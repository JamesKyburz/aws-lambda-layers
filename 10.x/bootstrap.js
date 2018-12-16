'use strict'

const http = require('http')
const { URL } = require('url')

const { hostname: host, port } = new URL(
  `http://${process.env.AWS_LAMBDA_RUNTIME_API}`
)

const handler = getHandler()

const baseContext = getBaseContext()

const next = () =>
  getNextInvocation(({ event, context }) => {
    const handleResult = (err, result) => {
      if (err) {
        postError(`/invocation/${context.awsRequestId}/error`, err, next)
      } else {
        post(
          {
            path: `/invocation/${context.awsRequestId}/response`,
            body: result
          },
          next
        )
      }
    }
    const promise = handler(event, context, handleResult)
    if (promise && promise.then) {
      promise.then(result => handleResult(null, result), handleResult)
    }
  })

next()

function getNextInvocation (next) {
  get({ path: '/invocation/next' }, res => {
    const {
      'lambda-runtime-trace-id': traceId,
      'lambda-runtime-deadline-ms': deadlineMs,
      'lambda-runtime-aws-request-id': awsRequestId,
      'lambda-runtime-invoked-function-arn': invokedFunctionArn,
      'lambda-runtime-client-context': clientContext,
      'lambda-runtime-cognito-identity': identity
    } = res.headers

    if (traceId) {
      process.env._X_AMZN_TRACE_ID = traceId
    } else {
      delete process.env._X_AMZN_TRACE_ID
    }

    const context = {
      awsRequestId,
      invokedFunctionArn,
      getRemainingTimeInMillis: () => deadlineMs - Date.now(),
      ...baseContext,
      ...(clientContext && { clientContext: JSON.parse(clientContext) }),
      ...(identity && { identity: JSON.parse(identity) })
    }

    next({ event: JSON.parse(res.body), context })
  })
}

function postError (
  path,
  { name: errorType, message: errorMessage, stack: stackTrace },
  cb
) {
  post(
    {
      path,
      headers: {
        'Content-Type': 'application/json',
        'Lambda-Runtime-Function-Error-Type': errorType
      },
      body: { errorType, errorMessage, stackTrace }
    },
    cb
  )
}

function post (options, cb) {
  request({ ...options, method: 'POST' }, cb)
}

function get (options, cb) {
  request({ ...options, method: 'GET' }, cb)
}

function request ({ path, method, headers, body }, next) {
  const req = http.request(
    {
      host,
      port,
      path: `/2018-06-01/runtime${path}`,
      method,
      ...(headers && { headers })
    },
    res => {
      const expectedStatus = method === 'POST' ? 202 : 200
      if (res.statusCode !== expectedStatus) {
        exit(
          new Error(
            `Unexpected response for [${method}]${path}: headers: ${
              res._headers
            }, status: ${res.statusCode}`
          )
        )
      } else {
        const data = []
        res.on('data', chunk => data.push(chunk))
        res.on('error', exit)
        res.on('end', () =>
          next({
            headers: res.headers,
            body: Buffer.concat(data).toString()
          })
        )
      }
    }
  )
  req.on('error', exit)
  req.end(body ? JSON.stringify(body) : undefined)
}

function getHandler () {
  const [rootPath, handlerPath, handlerName] = [
    process.env.LAMBDA_TASK_ROOT,
    ...process.env._HANDLER.split('.')
  ]
  try {
    return require(rootPath + '/' + handlerPath)[handlerName]
  } catch (err) {
    postError('init/error', err, () => exit(err))
  }
}

function getBaseContext () {
  const {
    AWS_LAMBDA_FUNCTION_NAME: functionName,
    AWS_LAMBDA_FUNCTION_VERSION: functionVersion,
    AWS_LAMBDA_FUNCTION_MEMORY_SIZE: memoryLimitInMB,
    AWS_LAMBDA_LOG_GROUP_NAME: logGroupName,
    AWS_LAMBDA_LOG_STREAM_NAME: logStreamName
  } = process.env

  return {
    logGroupName,
    logStreamName,
    functionName,
    functionVersion,
    memoryLimitInMB
  }
}

function exit (err) {
  console.error(err)
  process.exit(1)
}
