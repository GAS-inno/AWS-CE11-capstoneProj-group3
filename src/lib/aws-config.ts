import { Amplify } from 'aws-amplify'

const amplifyConfig = {
  Auth: {
    Cognito: {
      userPoolId: import.meta.env.VITE_AWS_USER_POOL_ID || '',
      userPoolClientId: import.meta.env.VITE_AWS_USER_POOL_CLIENT_ID || '',
      loginWith: {
        email: true,
        username: false,
        phone: false,
      },
      signUpVerificationMethod: 'code', // 'code' | 'link'
      userAttributes: {
        email: {
          required: true,
        },
        given_name: {
          required: true,
        },
        family_name: {
          required: true,
        },
      },
      allowGuestAccess: true,
      passwordFormat: {
        minLength: 8,
        requireLowercase: true,
        requireUppercase: true,
        requireNumbers: true,
        requireSpecialCharacters: true,
      },
    },
  },
  API: {
    REST: {
      BookingAPI: {
        endpoint: import.meta.env.VITE_AWS_API_GATEWAY_URL || '',
        region: import.meta.env.VITE_AWS_REGION || 'us-east-1',
      },
    },
  },
  Storage: {
    S3: {
      bucket: import.meta.env.VITE_AWS_S3_BUCKET || '',
      region: import.meta.env.VITE_AWS_REGION || 'us-east-1',
    },
  },
}

export const configureAWS = () => {
  try {
    Amplify.configure(amplifyConfig)
    console.log('AWS Amplify configured successfully')
  } catch (error) {
    console.error('Error configuring AWS Amplify:', error)
    throw new Error('Failed to configure AWS services')
  }
}

export { amplifyConfig }