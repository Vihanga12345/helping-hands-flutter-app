@echo off
echo 🚀 Deploying Gemini AI Chatbot to Supabase...

REM Set the Gemini API key as environment variable
echo 🔑 Setting Gemini API key...
supabase secrets set GEMINI_API_KEY=AIzaSyAW5J95WqXr_CtkY89HtKY2Uw1bgPEY76g

REM Deploy the Gemini chat function
echo 📦 Deploying Gemini chat function...
supabase functions deploy gemini-chat --no-verify-jwt

echo ✅ Deployment complete!
echo 🔗 Function URL: https://your-project-id.supabase.co/functions/v1/gemini-chat

pause 