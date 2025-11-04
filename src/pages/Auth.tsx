import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import { Plane } from "lucide-react";
import { useAuth } from "@/contexts/AWSAuthContext";
import { toast } from "sonner";
import { z } from "zod";

const authSchema = z.object({
  email: z.string().trim().email({ message: "Invalid email address" }).max(255),
  password: z
    .string()
    .min(6, { message: "Password must be at least 6 characters" })
    .max(100),
  firstName: z
    .string()
    .trim()
    .min(1, { message: "First name is required" })
    .max(50)
    .optional(),
  lastName: z
    .string()
    .trim()
    .min(1, { message: "Last name is required" })
    .max(50)
    .optional(),
});

const Auth = () => {
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [loading, setLoading] = useState(false);
  const [showVerification, setShowVerification] = useState(false);
  const [verificationCode, setVerificationCode] = useState("");
  const { signIn, signUp, confirmSignUp, user } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (user) {
      navigate("/");
    }
  }, [user, navigate]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      // Validate input
      const validationData = isLogin
        ? { email, password }
        : { email, password, firstName, lastName };

      authSchema.parse(validationData);

      if (isLogin) {
        const { error } = await signIn(email, password);
        if (error) {
          if (error.includes("Invalid login credentials")) {
            toast.error("Invalid email or password");
          } else if (error.includes("fetch")) {
            toast.error("Unable to connect to authentication service. Please check your internet connection or try again later.");
          } else {
            toast.error(error);
          }
        } else {
          toast.success("Welcome back!");
          navigate("/");
        }
      } else {
        const { error, requiresVerification } = await signUp(email, password, firstName, lastName);
        if (error) {
          if (error.includes("already registered")) {
            toast.error(
              "This email is already registered. Please sign in instead.",
            );
          } else if (error.includes("fetch")) {
            toast.error("Unable to connect to authentication service. Please check your internet connection or try again later.");
          } else {
            toast.error(error);
          }
        } else if (requiresVerification) {
          toast.success("Verification code sent to your email!");
          setShowVerification(true);
        } else {
          toast.success("Account created successfully! Welcome aboard!");
          navigate("/");
        }
      }
    } catch (error) {
      if (error instanceof z.ZodError) {
        error.errors.forEach((err) => {
          toast.error(err.message);
        });
      } else {
        toast.error("An unexpected error occurred");
      }
    } finally {
      setLoading(false);
    }
  };

  const handleVerification = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const { error } = await confirmSignUp(email, verificationCode);
      
      if (error) {
        toast.error(error);
      } else {
        toast.success("Email verified successfully! You can now sign in.");
        setShowVerification(false);
        setIsLogin(true);
        setVerificationCode("");
      }
    } catch (error) {
      toast.error("Failed to verify code");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-primary/5 via-background to-background flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="flex items-center justify-center gap-2 mb-4">
            <Plane className="w-10 h-10 text-primary" />
            <h1 className="text-4xl font-bold">SkyWings Airlines</h1>
          </div>
          <p className="text-muted-foreground">
            Your trusted partner for comfortable flights
          </p>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>
              {showVerification 
                ? "Verify Your Email" 
                : isLogin 
                  ? "Sign In" 
                  : "Create Account"}
            </CardTitle>
            <CardDescription>
              {showVerification
                ? "Enter the verification code sent to your email"
                : isLogin
                  ? "Welcome back! Sign in to continue your journey"
                  : "Join SkyWings Airlines and start your adventure"}
            </CardDescription>
          </CardHeader>
          <CardContent>
            {showVerification ? (
              <form onSubmit={handleVerification} className="space-y-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">Verification Code</label>
                  <Input
                    type="text"
                    placeholder="Enter 6-digit code"
                    value={verificationCode}
                    onChange={(e) => setVerificationCode(e.target.value)}
                    required
                    maxLength={6}
                    pattern="[0-9]*"
                  />
                  <p className="text-xs text-muted-foreground">
                    Check your email ({email}) for the verification code
                  </p>
                </div>

                <Button
                  type="submit"
                  className="w-full"
                  size="lg"
                  disabled={loading}
                >
                  {loading ? "Verifying..." : "Verify Email"}
                </Button>

                <div className="text-center text-sm">
                  <button
                    type="button"
                    onClick={() => {
                      setShowVerification(false);
                      setVerificationCode("");
                    }}
                    className="text-primary hover:underline font-medium"
                  >
                    Back to Sign Up
                  </button>
                </div>
              </form>
            ) : (
            <form onSubmit={handleSubmit} className="space-y-4">
              {!isLogin && (
                <>
                  <div className="space-y-2">
                    <label className="text-sm font-medium">First Name</label>
                    <Input
                      type="text"
                      placeholder="John"
                      value={firstName}
                      onChange={(e) => setFirstName(e.target.value)}
                      required={!isLogin}
                      maxLength={50}
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="text-sm font-medium">Last Name</label>
                    <Input
                      type="text"
                      placeholder="Doe"
                      value={lastName}
                      onChange={(e) => setLastName(e.target.value)}
                      required={!isLogin}
                      maxLength={50}
                    />
                  </div>
                </>
              )}

              <div className="space-y-2">
                <label className="text-sm font-medium">Email</label>
                <Input
                  type="email"
                  placeholder="your.email@example.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  maxLength={255}
                />
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium">Password</label>
                <Input
                  type="password"
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  minLength={6}
                  maxLength={100}
                />
              </div>

              <Button
                type="submit"
                className="w-full"
                size="lg"
                disabled={loading}
              >
                {loading
                  ? "Please wait..."
                  : isLogin
                    ? "Sign In"
                    : "Create Account"}
              </Button>

              <div className="text-center text-sm">
                <span className="text-muted-foreground">
                  {isLogin
                    ? "Don't have an account? "
                    : "Already have an account? "}
                </span>
                <button
                  type="button"
                  onClick={() => setIsLogin(!isLogin)}
                  className="text-primary hover:underline font-medium"
                >
                  {isLogin ? "Sign Up" : "Sign In"}
                </button>
              </div>
            </form>
            )}
          </CardContent>
        </Card>

        <div className="mt-4 text-center">
          <Button variant="ghost" onClick={() => navigate("/")}>
            Back to Home
          </Button>
        </div>
      </div>
    </div>
  );
};

export default Auth;
