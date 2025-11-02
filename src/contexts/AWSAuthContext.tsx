import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react'
import { signUp, signIn, signOut, getCurrentUser, fetchUserAttributes } from '@aws-amplify/auth'
import type { AuthUser, SignUpInput, SignInInput } from '@aws-amplify/auth'
import { configureAWS } from '@/lib/aws-config'

// User interface matching our booking system
export interface User {
  id: string
  email: string
  firstName?: string
  lastName?: string
  role?: 'user' | 'admin'
  emailVerified?: boolean
}

// Auth context interface
interface AuthContextType {
  user: User | null
  loading: boolean
  signUp: (email: string, password: string, firstName?: string, lastName?: string) => Promise<{ success: boolean; error?: string }>
  signIn: (email: string, password: string) => Promise<{ success: boolean; error?: string }>
  signOut: () => Promise<{ success: boolean; error?: string }>
  isAuthenticated: boolean
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

interface AuthProviderProps {
  children: ReactNode
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  // Initialize AWS Amplify
  useEffect(() => {
    try {
      configureAWS()
    } catch (error) {
      console.error('Failed to configure AWS:', error)
    }
  }, [])

  // Check for existing session
  useEffect(() => {
    const checkUser = async () => {
      try {
        const currentUser = await getCurrentUser()
        if (currentUser) {
          const attributes = await fetchUserAttributes()
          
          setUser({
            id: currentUser.userId,
            email: attributes.email || '',
            firstName: attributes.given_name || '',
            lastName: attributes.family_name || '',
            role: (attributes['custom:role'] as 'user' | 'admin') || 'user',
            emailVerified: attributes.email_verified === 'true',
          })
        }
      } catch (error) {
        console.log('No authenticated user found:', error)
        setUser(null)
      } finally {
        setLoading(false)
      }
    }

    checkUser()
  }, [])

  // Helper function to convert AuthUser to our User interface
  const convertToUser = async (authUser: AuthUser): Promise<User> => {
    const attributes = await fetchUserAttributes()
    
    return {
      id: authUser.userId,
      email: attributes.email || '',
      firstName: attributes.given_name || '',
      lastName: attributes.family_name || '',
      role: (attributes['custom:role'] as 'user' | 'admin') || 'user',
      emailVerified: attributes.email_verified === 'true',
    }
  }

  // Sign up function
  const handleSignUp = async (
    email: string,
    password: string,
    firstName?: string,
    lastName?: string
  ): Promise<{ success: boolean; error?: string }> => {
    try {
      const signUpInput: SignUpInput = {
        username: email,
        password,
        options: {
          userAttributes: {
            email,
            given_name: firstName || '',
            family_name: lastName || '',
          },
        },
      }

      const { isSignUpComplete, nextStep } = await signUp(signUpInput)
      
      if (isSignUpComplete) {
        return { success: true }
      } else if (nextStep.signUpStep === 'CONFIRM_SIGN_UP') {
        return { 
          success: true, 
          error: 'Please check your email for a confirmation code to complete registration.' 
        }
      } else {
        return { success: false, error: 'Sign up requires additional steps' }
      }
    } catch (error: unknown) {
      console.error('Sign up error:', error)
      const errorMessage = error instanceof Error ? error.message : 'Failed to create account. Please try again.'
      return { 
        success: false, 
        error: errorMessage
      }
    }
  }

  // Sign in function
  const handleSignIn = async (
    email: string, 
    password: string
  ): Promise<{ success: boolean; error?: string }> => {
    try {
      const signInInput: SignInInput = {
        username: email,
        password,
      }

      const { isSignedIn, nextStep } = await signIn(signInInput)
      
      if (isSignedIn) {
        const currentUser = await getCurrentUser()
        const userData = await convertToUser(currentUser)
        setUser(userData)
        return { success: true }
      } else if (nextStep.signInStep === 'CONFIRM_SIGN_UP') {
        return { 
          success: false, 
          error: 'Please confirm your email address before signing in.' 
        }
      } else {
        return { success: false, error: 'Sign in requires additional steps' }
      }
    } catch (error: unknown) {
      console.error('Sign in error:', error)
      
      let errorMessage = 'Unable to sign in. Please check your credentials.'
      
      if (error && typeof error === 'object' && 'name' in error) {
        const authError = error as { name: string; message?: string }
        if (authError.name === 'NotAuthorizedException') {
          errorMessage = 'Invalid email or password. Please try again.'
        } else if (authError.name === 'UserNotConfirmedException') {
          errorMessage = 'Please confirm your email address before signing in.'
        } else if (authError.name === 'NetworkError' || authError.message?.includes('fetch')) {
          errorMessage = 'Unable to connect to authentication service. Please check your internet connection.'
        }
      }
      
      return { success: false, error: errorMessage }
    }
  }

  // Sign out function
  const handleSignOut = async (): Promise<{ success: boolean; error?: string }> => {
    try {
      await signOut()
      setUser(null)
      return { success: true }
    } catch (error: unknown) {
      console.error('Sign out error:', error)
      const errorMessage = error instanceof Error ? error.message : 'Failed to sign out. Please try again.'
      return { 
        success: false, 
        error: errorMessage
      }
    }
  }

  const isAuthenticated = !!user

  const value: AuthContextType = {
    user,
    loading,
    signUp: handleSignUp,
    signIn: handleSignIn,
    signOut: handleSignOut,
    isAuthenticated,
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export { AuthContext }