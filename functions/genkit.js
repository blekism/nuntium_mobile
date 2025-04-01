// listModels.js
async function listAvailableModels(apiKey) {
    try {
      const response = await fetch(
        "https://generativelanguage.googleapis.com/v1beta/models",
        {
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": apiKey,
          },
        }
      );
  
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
  
      const data = await response.json();
      console.log(JSON.stringify(data, null, 2));
    } catch (error) {
      console.error("Error listing models:", error);
    }
  }
  
  async function main() {
    const apiKey = "AIzaSyAs80PkwTQR_eXyefC_6GaIh4a19kL4eng";
  
    if (!apiKey) {
      console.error("Error: GOOGLE_API_KEY environment variable not set.");
      return;
    }
  
    await listAvailableModels(apiKey);
  }
  
  if (require.main === module) {
    main();
  }