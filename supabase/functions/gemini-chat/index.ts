import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface ChatRequest {
  message: string;
  conversationId: string;
  userId?: string;
}

interface ChatResponse {
  message: string;
  buttons?: Array<{
    text: string;
    action: string;
    data?: any;
  }>;
  extractedData?: JobFormData;
  conversationComplete?: boolean;
  error?: string;
}

interface JobFormData {
  // Core fields (filled in order)
  jobCategoryId?: string;
  jobCategoryName?: string;
  jobPostingType?: string; // 'public' or 'private'
  selectedHelper?: any; // Helper object for private jobs
  defaultHourlyRate?: number;
  preferredDate?: string;
  preferredTime?: string;
  location?: string;
  description?: string;
  title?: string;
  
  // Job-specific question answers
  jobQuestionAnswers?: Array<{
    questionId: string;
    question: string;
    answer: string;
  }>;
  
  // State tracking
  currentField?: string;
  nextField?: string;
  currentQuestionId?: string;
  confidence: number;
  isComplete: boolean;
}

interface ConversationState {
  conversationId: string;
  userId: string;
  currentStep: string;
  collectedData: JobFormData;
  jobCategories: any[];
  jobQuestions: any[];
  foundHelpers: any[]; // Store found helpers for selection
  askedQuestions: string[];
  lastMessage: string;
  createdAt: string;
  updatedAt: string;
}

// Core field processing order (must be followed sequentially)
const FIELD_ORDER = [
  'jobCategory',      // 1. First: Determine job type
  'jobPostingType',   // 2. Then: Ask if public or private
  'helperSelection',  // 3. If private: Select specific helper
  'jobQuestions',     // 4. Then: Ask job-specific questions (if any)
  'preferredDate',    // 5. When do you need this done?
  'preferredTime',    // 6. What time works best?
  'location',         // 7. Where should this be done?
  'description',      // 8. Any additional details?
  'title'            // 9. Finally: Generate title and complete
];

const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY") || "";

// Initialize Supabase client
const supabase = createClient(supabaseUrl, supabaseKey);

console.log("🤖 Gemini Chat Edge Function starting...");

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    });
  }

  try {
    const { message, conversationId, userId }: ChatRequest = await req.json();
    
    console.log(`📨 Processing message: "${message}" for conversation: ${conversationId}`);
    
    // Get or create conversation state
    const state = await getConversationState(conversationId, userId);
    
    // Process the message and update state
    const response = await processMessage(message, state);
    
    // Save updated state
    await saveConversationState(state);
    
    console.log(`✅ Response generated: ${response.message.substring(0, 100)}...`);
    
    return new Response(JSON.stringify(response), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
    
  } catch (error) {
    console.error('❌ Gemini Chat Error:', error);
    
    return new Response(
      JSON.stringify({
        message: "I'm having trouble right now. Please try again in a moment.",
        error: error.message
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        status: 500,
      }
    );
  }
});

// Get or create conversation state
async function getConversationState(conversationId: string, userId: string): Promise<ConversationState> {
  try {
    // Try to get existing conversation state
    const { data: existingState } = await supabase
      .from('ai_conversation_states')
      .select('*')
      .eq('conversation_id', conversationId)
      .single();
    
    if (existingState) {
      return {
        conversationId: existingState.conversation_id,
        userId: existingState.user_id,
        currentStep: existingState.current_step || 'jobCategory',
        collectedData: existingState.collected_data || getEmptyJobData(),
              jobCategories: existingState.job_categories || [],
      jobQuestions: existingState.job_questions || [],
      foundHelpers: [], // Initialize empty helper list
      askedQuestions: existingState.asked_questions || [],
        lastMessage: existingState.last_message || '',
        createdAt: existingState.created_at,
        updatedAt: existingState.updated_at
      };
    }
  } catch (error) {
    console.log('Creating new conversation state');
  }
  
  // Create new conversation state
  const jobCategories = await getJobCategories();
  
  return {
    conversationId,
    userId: userId || 'anonymous',
    currentStep: 'jobCategory',
    collectedData: getEmptyJobData(),
    jobCategories,
    jobQuestions: [],
    foundHelpers: [], // Initialize empty helper list
    askedQuestions: [],
    lastMessage: '',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
}

// Get empty job data structure
function getEmptyJobData(): JobFormData {
  return {
    confidence: 0,
    isComplete: false,
    currentField: 'jobCategory',
    nextField: 'jobQuestions',
    jobQuestionAnswers: []
  };
}

// Get job categories from database
async function getJobCategories(): Promise<any[]> {
  try {
    const { data: categories } = await supabase
      .from('job_categories')
      .select('id, name, description, default_hourly_rate')
      .eq('is_active', true)
      .order('name');
    
    return categories || [];
  } catch (error) {
    console.error('Error fetching job categories:', error);
    return [];
  }
}

// Get job-specific questions for a category
async function getJobQuestions(categoryId: string): Promise<any[]> {
  try {
    const { data: questions } = await supabase
      .from('job_category_questions')
      .select('id, question, question_text, question_type, is_required, placeholder_text, order_index, question_order')
      .eq('category_id', categoryId)
      .eq('is_active', true)
      .order('order_index');
    
    return questions || [];
  } catch (error) {
    console.error('Error fetching job questions:', error);
    return [];
  }
}

// Main message processing logic
async function processMessage(message: string, state: ConversationState): Promise<ChatResponse> {
  const userMessage = message.trim().toLowerCase();
  
  console.log(`🔄 Processing step: ${state.currentStep} with message: "${message}"`);
  
  // Handle the current step
  switch (state.currentStep) {
    case 'jobCategory':
      return await handleJobCategoryStep(message, state);
      
    case 'jobPostingType':
      return await handleJobPostingTypeStep(message, state);
      
    case 'helperSelection':
      return await handleHelperSelectionStep(message, state);
      
    case 'jobQuestions':
      return await handleJobQuestionsStep(message, state);
      
    case 'preferredDate':
      return await handleDateStep(message, state);
      
    case 'preferredTime':
      return await handleTimeStep(message, state);
      
    case 'location':
      return await handleLocationStep(message, state);
      
    case 'description':
      return await handleDescriptionStep(message, state);
      
    case 'title':
      return await handleTitleStep(message, state);
      
    case 'complete':
      return await handleCompleteStep(message, state);
      
    default:
      // Fallback to job category step
      state.currentStep = 'jobCategory';
      return await handleJobCategoryStep(message, state);
  }
}

// Handle job category selection
async function handleJobCategoryStep(message: string, state: ConversationState): Promise<ChatResponse> {
  const data = state.collectedData;
  
  // If we already have a job category, move to next step
  if (data.jobCategoryId) {
    state.currentStep = 'jobPostingType';
    return await handleJobPostingTypeStep(message, state);
  }
  
  // Try to match job category from message
  const matchedCategory = findBestCategoryMatch(message, state.jobCategories);
  
  if (matchedCategory) {
    // Found a match - confirm with user
    data.jobCategoryId = matchedCategory.id;
    data.jobCategoryName = matchedCategory.name;
    data.defaultHourlyRate = matchedCategory.default_hourly_rate;
    data.confidence = 0.2;
    data.currentField = 'jobCategory';
    data.nextField = 'jobPostingType';
    
    // Get job-specific questions for this category (for later use)
    state.jobQuestions = await getJobQuestions(matchedCategory.id);
    
    // Move to next step
    state.currentStep = 'jobPostingType';
    state.lastMessage = message;
    
    const nextMessage = `Great! I understand you need help with ${matchedCategory.name}. \n\nNow, would you like to post this as a **public job** (visible to all helpers) or a **private job** (invite a specific helper)?`;
    
    return {
      message: nextMessage,
      extractedData: data
    };
  } else {
    // No clear match - ask for clarification or show options
    const suggestions = state.jobCategories.slice(0, 6).map(cat => cat.name).join(', ');
    
    return {
      message: `I'd be happy to help you! Could you please tell me what type of service you need? For example, I can help with: ${suggestions}, and many others. What kind of help are you looking for?`,
      extractedData: data
    };
  }
}

// Handle job posting type (public/private)
async function handleJobPostingTypeStep(message: string, state: ConversationState): Promise<ChatResponse> {
  const data = state.collectedData;
  
  if (data.jobPostingType) {
    // Already have posting type, move to next step
    if (data.jobPostingType === 'private') {
      state.currentStep = 'helperSelection';
      return await handleHelperSelectionStep(message, state);
    } else {
      state.currentStep = 'jobQuestions';
      return await handleJobQuestionsStep(message, state);
    }
  }
  
  const messageLower = message.toLowerCase();
  
  if (messageLower.includes('private') || messageLower.includes('specific') || messageLower.includes('invite')) {
    data.jobPostingType = 'private';
    data.confidence += 0.1;
    data.currentField = 'jobPostingType';
    data.nextField = 'helperSelection';
    
    state.currentStep = 'helperSelection';
    
    return {
      message: `Perfect! You want to invite a specific helper. Could you tell me the name of the helper you'd like to invite for this ${data.jobCategoryName} job?`,
      extractedData: data
    };
  } else if (messageLower.includes('public') || messageLower.includes('all') || messageLower.includes('anyone')) {
    data.jobPostingType = 'public';
    data.confidence += 0.1;
    data.currentField = 'jobPostingType';
    data.nextField = 'jobQuestions';
    
    state.currentStep = 'jobQuestions';
    
    const hasJobQuestions = state.jobQuestions.length > 0;
    const nextMessage = hasJobQuestions 
      ? `Great! This will be a public job visible to all helpers. Let me ask you some specific questions about your ${data.jobCategoryName} needs.`
      : `Perfect! This will be a public job visible to all helpers. When would you like this ${data.jobCategoryName} service done?`;
    
    return {
      message: nextMessage,
      extractedData: data
    };
  } else {
    return {
      message: `Would you like to post this as:\n\n**Public job** - Visible to all helpers who can apply\n**Private job** - Invite a specific helper you prefer\n\nPlease choose "public" or "private".`,
      extractedData: data
    };
  }
}

// Handle helper selection for private jobs
async function handleHelperSelectionStep(message: string, state: ConversationState): Promise<ChatResponse> {
  const data = state.collectedData;
  
  if (data.selectedHelper) {
    // Already have helper, move to job questions
    state.currentStep = 'jobQuestions';
    return await handleJobQuestionsStep(message, state);
  }
  
  // Check if user is confirming a helper from a previous list
  if (state.foundHelpers && state.foundHelpers.length > 0) {
    const selectedHelper = findHelperFromList(message.trim(), state.foundHelpers);
    
    if (selectedHelper) {
      data.selectedHelper = selectedHelper;
      data.confidence += 0.15;
      data.currentField = 'helperSelection';
      data.nextField = 'jobQuestions';
      
      state.currentStep = 'jobQuestions';
      state.foundHelpers = []; // Clear the helper list
      
      const hasJobQuestions = state.jobQuestions.length > 0;
      const nextMessage = hasJobQuestions 
        ? `Excellent! I found **${selectedHelper.full_name}** and they'll be invited for this ${data.jobCategoryName} job. Let me ask you some specific questions about your needs.`
        : `Perfect! **${selectedHelper.full_name}** will be invited for this ${data.jobCategoryName} job. When would you like this service done?`;
      
      return {
        message: nextMessage,
        extractedData: data
      };
    }
  }
  
  // Search for helpers by partial name
  const helpers = await findHelpersByPartialName(message.trim());
  
  if (helpers.length === 1) {
    // Exactly one match - select automatically
    data.selectedHelper = helpers[0];
    data.confidence += 0.15;
    data.currentField = 'helperSelection';
    data.nextField = 'jobQuestions';
    
    state.currentStep = 'jobQuestions';
    
    const hasJobQuestions = state.jobQuestions.length > 0;
    const nextMessage = hasJobQuestions 
      ? `Perfect! I found **${helpers[0].full_name}** and they'll be invited for this ${data.jobCategoryName} job. Let me ask you some specific questions about your needs.`
      : `Excellent! **${helpers[0].full_name}** will be invited for this ${data.jobCategoryName} job. When would you like this service done?`;
    
    return {
      message: nextMessage,
      extractedData: data
    };
  } else if (helpers.length > 1) {
    // Multiple matches - show list for user to choose
    state.foundHelpers = helpers;
    
    let helperList = `I found **${helpers.length} helpers** matching "${message}". Please choose one:\n\n`;
    
    helpers.forEach((helper, index) => {
      const rating = helper.rating ? `⭐ ${helper.rating}/5` : '⭐ New helper';
      const jobCount = helper.total_jobs_completed || 0;
      const jobTypes = helper.job_type_names && helper.job_type_names.length > 0 
        ? helper.job_type_names.slice(0, 2).join(', ') 
        : 'Various services';
      
      helperList += `**${index + 1}. ${helper.full_name}**\n`;
      helperList += `   ${rating} • ${jobCount} jobs completed\n`;
      helperList += `   Specializes in: ${jobTypes}\n\n`;
    });
    
    helperList += `Please type the **full name** of the helper you'd like to invite, or say "public" to make this a public job instead.`;
    
    return {
      message: helperList,
      extractedData: data
    };
  } else {
    // No matches found
    return {
      message: `I couldn't find any helpers matching "${message}". Could you try:\n\n• **Different spelling** or **partial name** (e.g., "John", "Sarah")\n• **Full first name** of the helper\n• Or say **"public"** to make this a public job instead`,
      extractedData: data
    };
  }
}

// Helper function to find multiple helpers by partial name
async function findHelpersByPartialName(name: string): Promise<any[]> {
  try {
    console.log(`🔍 Searching for helpers with name: "${name}"`);
    
    const { data: helpers, error } = await supabase
      .from('users')
      .select('id, full_name, profile_image_url, job_type_names, rating, total_jobs_completed')
      .eq('role', 'helper')
      .ilike('full_name', `%${name}%`)
      .order('rating', { ascending: false })
      .order('total_jobs_completed', { ascending: false })
      .limit(10); // Return up to 10 matches
    
    if (error) {
      console.error('❌ Error finding helpers:', error);
      return [];
    }
    
    console.log(`✅ Found ${helpers?.length || 0} helpers matching "${name}"`);
    if (helpers) {
      helpers.forEach((helper, index) => {
        console.log(`${index + 1}. ${helper.full_name} (Rating: ${helper.rating}, Jobs: ${helper.total_jobs_completed})`);
      });
    }
    
    return helpers || [];
  } catch (error) {
    console.error('❌ Error in findHelpersByPartialName:', error);
    return [];
  }
}

// Helper function to find a specific helper from a list by exact name match
function findHelperFromList(name: string, helpers: any[]): any {
  const nameLower = name.toLowerCase().trim();
  
  // Try exact match first
  let match = helpers.find(helper => 
    helper.full_name.toLowerCase() === nameLower
  );
  
  if (match) return match;
  
  // Try partial match (in case user didn't type the full name exactly)
  match = helpers.find(helper => 
    helper.full_name.toLowerCase().includes(nameLower) || 
    nameLower.includes(helper.full_name.toLowerCase())
  );
  
  return match || null;
}

// Handle job-specific questions
async function handleJobQuestionsStep(message: string, state: ConversationState): Promise<ChatResponse> {
  const data = state.collectedData;
  
  // If no job-specific questions, move to date
  if (state.jobQuestions.length === 0) {
    state.currentStep = 'preferredDate';
    return await handleDateStep(message, state);
  }
  
  // If we have a current question being asked, save the answer first
  if (data.currentQuestionId) {
    const currentQuestion = state.jobQuestions.find(q => q.id === data.currentQuestionId);
    if (currentQuestion) {
      // Save the answer
      if (!data.jobQuestionAnswers) data.jobQuestionAnswers = [];
      
      data.jobQuestionAnswers.push({
        questionId: currentQuestion.id,
        question: currentQuestion.question || currentQuestion.question_text,
        answer: message
      });
      
      data.confidence += 0.1;
      state.askedQuestions.push(currentQuestion.id);
    }
    
    data.currentQuestionId = undefined;
  }
  
  // Now calculate answered questions AFTER saving the current answer
  const answeredQuestionIds = (data.jobQuestionAnswers || []).map(a => a.questionId);
  
  // Find the next unanswered required question
  const nextQuestion = state.jobQuestions.find(q => 
    !answeredQuestionIds.includes(q.id) && q.is_required
  );
  
  // Check if we have more questions to ask
  if (nextQuestion) {
    // Ask the next question
    data.currentQuestionId = nextQuestion.id;
    data.currentField = 'jobQuestions';
    
    const questionText = nextQuestion.question || nextQuestion.question_text;
    const placeholder = nextQuestion.placeholder_text ? ` (${nextQuestion.placeholder_text})` : '';
    
    return {
      message: questionText + placeholder,
      extractedData: data
    };
  } else {
    // All required questions answered, move to date
    state.currentStep = 'preferredDate';
    data.currentField = 'preferredDate';
    data.nextField = 'preferredTime';
    
    return {
      message: "Thank you for those details! When would you like this service? You can say something like 'tomorrow', 'next Monday', or give me a specific date.",
      extractedData: data
    };
  }
}

// Handle preferred date
async function handleDateStep(message: string, state: ConversationState): Promise<ChatResponse> {
  const data = state.collectedData;
  
  if (data.preferredDate) {
    // Already have date, move to time
    state.currentStep = 'preferredTime';
    return await handleTimeStep(message, state);
  }
  
  const extractedDate = extractDateFromMessage(message);
  
  if (extractedDate) {
    data.preferredDate = extractedDate;
    data.confidence += 0.15;
    data.currentField = 'preferredDate';
    data.nextField = 'preferredTime';
    
    state.currentStep = 'preferredTime';
    
    return {
      message: `Perfect! I have ${formatDate(extractedDate)} scheduled. What time would work best for you? (e.g., '9 AM', 'afternoon', '2:30 PM')`,
      extractedData: data
    };
  } else {
    return {
      message: "I didn't quite catch the date. Could you tell me when you'd like this done? For example: 'tomorrow', 'this Friday', 'January 15th', etc.",
      extractedData: data
    };
  }
}

// Handle preferred time
async function handleTimeStep(message: string, state: ConversationState): Promise<ChatResponse> {
  const data = state.collectedData;
  
  if (data.preferredTime) {
    // Already have time, move to location
    state.currentStep = 'location';
    return await handleLocationStep(message, state);
  }
  
  const extractedTime = extractTimeFromMessage(message);
  
  if (extractedTime) {
    data.preferredTime = extractedTime;
    data.confidence += 0.15;
    data.currentField = 'preferredTime';
    data.nextField = 'location';
    
    state.currentStep = 'location';
    
    return {
      message: `Great! I have ${extractedTime} noted. Where should this service be provided? Please provide the address or location.`,
      extractedData: data
    };
  } else {
    return {
      message: "What time would work best for you? You can say something like '9 AM', '2:30 PM', 'morning', 'afternoon', etc.",
      extractedData: data
    };
  }
}

// Handle location
async function handleLocationStep(message: string, state: ConversationState): Promise<ChatResponse> {
  const data = state.collectedData;
  
  if (data.location) {
    // Already have location, move to description
    state.currentStep = 'description';
    return await handleDescriptionStep(message, state);
  }
  
  // Simple location extraction - any non-empty message is considered a location
  if (message.trim().length > 3) {
    data.location = message.trim();
    data.confidence += 0.15;
    data.currentField = 'location';
    data.nextField = 'description';
    
    state.currentStep = 'description';
    
    return {
      message: `Perfect! I have the location as: ${data.location}. Now, could you provide any additional details or special requirements for this ${data.jobCategoryName} job?`,
      extractedData: data
    };
  } else {
    return {
      message: "Could you please provide the address or location where this service should be provided?",
      extractedData: data
    };
  }
}

// Handle description
async function handleDescriptionStep(message: string, state: ConversationState): Promise<ChatResponse> {
  const data = state.collectedData;
  
  if (data.description) {
    // Already have description, move to title generation
    state.currentStep = 'title';
    return await handleTitleStep(message, state);
  }
  
  if (message.trim().length > 5) {
    data.description = message.trim();
    data.confidence += 0.15;
    data.currentField = 'description';
    data.nextField = 'title';
    
    // Generate job title
    const generatedTitle = generateJobTitle(data);
    data.title = generatedTitle;
    data.confidence = Math.min(data.confidence + 0.2, 1.0);
    data.isComplete = true;
    data.currentField = 'complete';
    
    state.currentStep = 'complete';
    
    return {
      message: `Excellent! I have all the information I need. I've created a job request titled "${generatedTitle}". Click below to review and submit your job request.`,
      extractedData: data,
      conversationComplete: true,
      buttons: [
        { text: "Review & Submit", action: "navigate_to_form", data: { action: "submit" } }
      ]
    };
  } else {
    return {
      message: "Could you provide some additional details about what you need help with? This will help potential helpers understand your requirements better.",
      extractedData: data
    };
  }
}

// Handle title generation and completion
async function handleTitleStep(message: string, state: ConversationState): Promise<ChatResponse> {
  const data = state.collectedData;
  
  // Generate title if not already done
  if (!data.title) {
    data.title = generateJobTitle(data);
    data.confidence = Math.min(data.confidence + 0.2, 1.0);
  }
  
  data.isComplete = true;
  data.currentField = 'complete';
  state.currentStep = 'complete';
  
  return {
    message: `Perfect! I've created your job request: "${data.title}". Everything looks good! Would you like to review and submit this job request?`,
    extractedData: data,
    conversationComplete: true,
    buttons: [
      { text: "Review & Submit", action: "navigate_to_form", data: { action: "submit" } },
      { text: "Make Changes", action: "navigate_to_form", data: { action: "edit" } }
    ]
  };
}

// Handle completion step
async function handleCompleteStep(message: string, state: ConversationState): Promise<ChatResponse> {
  const data = state.collectedData;
  
  return {
    message: `Your job request "${data.title}" is ready! Use the buttons below to review and submit it.`,
    extractedData: data,
    conversationComplete: true,
    buttons: [
      { text: "Review & Submit", action: "navigate_to_form", data: { action: "submit" } },
      { text: "Start New Request", action: "restart_conversation", data: {} }
    ]
  };
}

// Find best category match using simple keyword matching
function findBestCategoryMatch(message: string, categories: any[]): any | null {
  const text = message.toLowerCase();
  
  // Direct name matches
  for (const category of categories) {
    if (text.includes(category.name.toLowerCase())) {
      return category;
    }
  }
  
  // Keyword-based matching
  const keywords: { [key: string]: string[] } = {
    'House Cleaning': ['clean', 'cleaning', 'house', 'home', 'tidy', 'sweep', 'mop', 'dust'],
    'Deep Cleaning': ['deep clean', 'thorough', 'deep', 'spring clean'],
    'Gardening': ['garden', 'gardening', 'lawn', 'plants', 'yard', 'landscaping', 'grass', 'weeds'],
    'Cooking': ['cook', 'cooking', 'meal', 'chef', 'food', 'kitchen', 'prepare'],
    'Elderly Care': ['elderly', 'senior', 'care', 'companion', 'old'],
    'Child Care': ['child', 'kids', 'baby', 'babysit', 'nanny', 'children'],
    'Pet Care': ['pet', 'dog', 'cat', 'animal', 'walk', 'sitting'],
    'Tutoring': ['tutor', 'teach', 'study', 'homework', 'lesson', 'education'],
    'Tech Support': ['computer', 'tech', 'laptop', 'phone', 'repair', 'fix'],
    'Moving Help': ['move', 'moving', 'relocate', 'pack', 'boxes']
  };
  
  for (const [categoryName, words] of Object.entries(keywords)) {
    for (const word of words) {
      if (text.includes(word)) {
        return categories.find(c => c.name === categoryName);
      }
    }
  }
  
  return null;
}

// Extract date from message
function extractDateFromMessage(message: string): string | null {
  const text = message.toLowerCase();
  const today = new Date();
  
  if (text.includes('today')) {
    return formatDateForStorage(today);
  }
  
  if (text.includes('tomorrow')) {
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    return formatDateForStorage(tomorrow);
  }
  
  if (text.includes('monday') || text.includes('mon')) {
    return getNextWeekday(1);
  }
  if (text.includes('tuesday') || text.includes('tue')) {
    return getNextWeekday(2);
  }
  if (text.includes('wednesday') || text.includes('wed')) {
    return getNextWeekday(3);
  }
  if (text.includes('thursday') || text.includes('thu')) {
    return getNextWeekday(4);
  }
  if (text.includes('friday') || text.includes('fri')) {
    return getNextWeekday(5);
  }
  if (text.includes('saturday') || text.includes('sat')) {
    return getNextWeekday(6);
  }
  if (text.includes('sunday') || text.includes('sun')) {
    return getNextWeekday(0);
  }
  
  // Try to parse specific dates
  const dateRegex = /(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})/;
  const match = text.match(dateRegex);
  if (match) {
    const month = parseInt(match[1]);
    const day = parseInt(match[2]);
    const year = parseInt(match[3]) + (match[3].length === 2 ? 2000 : 0);
    
    const date = new Date(year, month - 1, day);
    if (!isNaN(date.getTime())) {
      return formatDateForStorage(date);
    }
  }
  
  return null;
}

// Extract time from message
function extractTimeFromMessage(message: string): string | null {
  const text = message.toLowerCase();
  
  // Common time phrases
  if (text.includes('morning')) return '09:00';
  if (text.includes('afternoon')) return '14:00';
  if (text.includes('evening')) return '18:00';
  if (text.includes('night')) return '20:00';
  
  // Specific times
  const timeRegex = /(\d{1,2})(?::(\d{2}))?\s*(am|pm)?/i;
  const match = text.match(timeRegex);
  
  if (match) {
    let hour = parseInt(match[1]);
    const minute = match[2] ? parseInt(match[2]) : 0;
    const ampm = match[3] ? match[3].toLowerCase() : '';
    
    if (ampm === 'pm' && hour !== 12) hour += 12;
    if (ampm === 'am' && hour === 12) hour = 0;
    
    return `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;
  }
  
  return null;
}

// Generate job title
function generateJobTitle(data: JobFormData): string {
  const category = data.jobCategoryName || 'Service';
  const location = data.location ? ` in ${data.location.split(',')[0]}` : '';
  const date = data.preferredDate ? ` on ${formatDate(data.preferredDate)}` : '';
  
  return `${category} Help${location}${date}`;
}

// Utility functions
function formatDateForStorage(date: Date): string {
  return date.toISOString().split('T')[0];
}

function formatDate(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleDateString('en-US', { 
    weekday: 'long', 
    year: 'numeric', 
    month: 'long', 
    day: 'numeric' 
  });
}

function getNextWeekday(targetDay: number): string {
  const today = new Date();
  const currentDay = today.getDay();
  const daysUntilTarget = (targetDay - currentDay + 7) % 7;
  const targetDate = new Date(today);
  targetDate.setDate(today.getDate() + (daysUntilTarget === 0 ? 7 : daysUntilTarget));
  return formatDateForStorage(targetDate);
}

// Save conversation state
async function saveConversationState(state: ConversationState): Promise<void> {
  try {
    state.updatedAt = new Date().toISOString();
    
    await supabase
      .from('ai_conversation_states')
      .upsert({
        conversation_id: state.conversationId,
        user_id: state.userId,
        current_step: state.currentStep,
        collected_data: state.collectedData,
        job_categories: state.jobCategories,
        job_questions: state.jobQuestions,
        asked_questions: state.askedQuestions,
        last_message: state.lastMessage,
        created_at: state.createdAt,
        updated_at: state.updatedAt
      }, {
        onConflict: 'conversation_id'
      });
      
    console.log(`💾 Conversation state saved for: ${state.conversationId}`);
  } catch (error) {
    console.error('Error saving conversation state:', error);
  }
} 