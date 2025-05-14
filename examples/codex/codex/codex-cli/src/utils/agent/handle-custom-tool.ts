import axios from 'axios';

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