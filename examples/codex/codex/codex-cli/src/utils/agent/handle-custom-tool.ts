import axios from 'axios';
import OpenAI from 'openai';
const fs = require('fs');

/**
 * Searches Stack Overflow for the given query and returns the results
 * @param query The search query string
 * @returns A string containing the search results from Stack Overflow
 */
export async function handleSearchTool(query: string): Promise<string> {
    let attempts = 0;
    const maxAttempts = 3;
    
    while (attempts < maxAttempts) {
        try {
            attempts++;
            // Create a search-friendly query string
            const encodedQuery = encodeURIComponent(query);
            
            // Using Stack Exchange API to search for questions
            const response = await axios.get(
                `https://api.stackexchange.com/2.3/search?order=desc&sort=relevance&intitle=${encodedQuery}&site=stackoverflow`
            );
            
            if (!response.data || !response.data.items || response.data.items.length === 0) {
                console.log(`Attempt ${attempts}: No results found, got ${JSON.stringify(response.data)}`);
                if (attempts < maxAttempts) {
                    console.log(`Attempt ${attempts}: No results found. Retrying...`);
                    continue;
                } else {
                    return `No results found on Stack Overflow for your query "${query}" after ${maxAttempts} attempts.`;
                }
            }
            
            // Format the results
            const topResults = response.data.items.slice(0, 5); // Get top 5 results
            let formattedResult = `Search results for "${query}" on Stack Overflow:\n\n`;
            
            topResults.forEach((item: any, index: number) => {
                formattedResult += `${index + 1}. ${item.title}\n`;
                formattedResult += `   Score: ${item.score}, Answers: ${item.answer_count}\n`;
                formattedResult += `   Link: ${item.link}\n\n`;
            });
            
            return formattedResult;
        } catch (error) {
            if (attempts < maxAttempts) {
                console.log(`Attempt ${attempts}: Error searching Stack Overflow. Retrying...`);
                continue;
            } else {
                console.error('Error searching Stack Overflow:', error);
                return `Failed to search Stack Overflow after ${maxAttempts} attempts: ${error instanceof Error ? error.message : String(error)}`;
            }
        }
    }
    
    // This line should not be reached due to the returns in the loop
    return `Failed to search Stack Overflow after ${maxAttempts} attempts.`;
}

/**
 * Generates a report using an AI model based on the provided message
 * @param message The user message to generate a report for
 * @returns A string containing the AI-generated report
 */
export async function handleReportTool(message: string): Promise<string> {
    let attempts = 0;
    const maxAttempts = 3;
    
    // Initialize OpenAI client (assumes API key is in environment variables)
    const openai = new OpenAI({
        apiKey: process.env['OPENAI_API_KEY'],
    });

    const systemPrompt = `You are a helpful manager that reviews the work of your interns. It is important to be concise in the feedback and avoid using a lot of bullet points. No need to encourage too much: just tell them what to do next. The task of your intern is to reproduce the environment setup for running an open-source repository. They should be able to complete the task end-to-end, install dependencies, change configs if necessary, and run the code. If they are not running the code, remind them that they should do it themselves and that they have the ability to do it. You should also analyze the log to see if they have successfully tried to reproduce the environment setup and tested it. If they run into any problems, ask them to take a step back, think about the problem, and try something new to solve it. If they are stuck, give some ideas to help them out. Remember to provide useful, immediately actionable feedback. Be concise. Be assertive if the intern is not doing their job.`;

    // Read file path from log_path.txt
    async function readLogPath(): Promise<string> {
        try {
            // Use an absolute path or an environment variable for the log path
            const logPathFile = process.env['LOG_PATH_FILE'] || '/home/ubuntu/EnvGym/examples/codex/output/current_log.txt';
            return fs.readFileSync(logPathFile, 'utf8').trim();
        } catch (error) {
            console.error('Error reading log path file:', error, "\nUse LOG_PATH_FILE environment variable to set the absolute log path.");
            throw new Error('Failed to read log path file');
        }
    }

    // Read log content from the path specified in log_path.txt
    async function readLogContent(): Promise<string> {
        try {
            const logPath = await readLogPath();
            return fs.readFileSync(logPath, 'utf8');
        } catch (error) {
            console.error('Error reading log content:', error);
            throw new Error('Failed to read log content');
        }
    }

    var logContent;
    // Augment the message with the log content
    // Attempt to read log content - throw error if this fails
    logContent = await readLogContent();
    // Limit log content to last 3000 characters
    if (logContent.length > 3000) {
        logContent = "...(truncated)..." + logContent.slice(-3000);
    }

    // Log the log content for debugging purposes
    console.log('Log content loaded:', logContent ? `${logContent.length} characters` : 'ERROR: NO CONTENT LOADED');
    
    while (attempts < maxAttempts) {
        try {
            attempts++;
            
            const response = await openai.chat.completions.create({
                model: "gpt-4.1-mini",
                messages: [
                    { role: "system", content: systemPrompt },
                    { role: "user", content: "[Intern] Here is the log of my work so far. Please analyze it and provide concise feedback." },
                    { role: "user", content: logContent},
                    { role: "user", content: "[Intern] Hi! I am working on the task of reproducing the environment setup for running an open-source repository. Please provide concise feedback on my work, expecially: tell me what to do next. Be concise and expect me to have relevant knowledge." },
                    { role: "user", content: message }
                ],
                temperature: 0.7,
            });
            
            if (!response.choices || response.choices.length === 0) {
                console.log(`Attempt ${attempts}: No response generated.`);
                if (attempts < maxAttempts) {
                    console.log(`Retrying...`);
                    continue;
                } else {
                    return `Failed to generate a report for "${message}" after ${maxAttempts} attempts.`;
                }
            }
            
            const generatedContent = response.choices[0].message?.content;
            if (generatedContent) {
                return `[user]: ${generatedContent}`;
            } else {
                return `Generated an empty report for "${message}". Please try again with more details.`;
            }
            
        } catch (error) {
            if (attempts < maxAttempts) {
                console.log(`Attempt ${attempts}: Error generating report. Retrying...`);
                continue;
            } else {
                console.error('Error generating report:', error);
                return `Failed to generate report after ${maxAttempts} attempts: ${error instanceof Error ? error.message : String(error)}`;
            }
        }
    }
    
    return `Failed to generate a report after ${maxAttempts} attempts.`;
}


