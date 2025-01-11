using Azure.Identity;
using Azure.Storage.Blobs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace StorageExplorerAPI
{
    public class StorageExplorerCalls
    {
        private readonly ILogger _logger;
        private readonly string _storageUri;
        private readonly string _containerName;

        public StorageExplorerCalls(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<StorageExplorerCalls>();
            _storageUri = "https://rudistorage12345.blob.core.windows.net/";
            _containerName = "blobs";
        }

        [Function("GetAllFiles")]
        public async Task<HttpResponseData> GetAllFilesAsync([HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequestData req)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");

            try
            {
                var blobServiceClient = new BlobServiceClient(new Uri(_storageUri), new DefaultAzureCredential());
                var containerClient = blobServiceClient.GetBlobContainerClient(_containerName);

                var blobs = containerClient.GetBlobsAsync();
                List<string> blobNames = new List<string>();
                await foreach (var blob in blobs)
                {
                    blobNames.Add(blob.Name);
                    _logger.LogInformation($"Blob name: {blob.Name}");
                }

                var response = req.CreateResponse(HttpStatusCode.OK);
                response.Headers.Add("Content-Type", "application/json; charset=utf-8");
                await response.WriteAsJsonAsync(blobNames);

                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError($"An error occurred: {ex.Message}");
                var response = req.CreateResponse(HttpStatusCode.InternalServerError);
                response.Headers.Add("Content-Type", "text/plain; charset=utf-8");
                response.WriteString($"An error occurred: {ex.Message}");
                return response;
            }
        }

        [Function("ReadFile")]
        public async Task<HttpResponseData> ReadFileAsync([HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequestData req, string blobName)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");

            if (String.IsNullOrEmpty(blobName))
            {
                var response = req.CreateResponse(HttpStatusCode.BadRequest);
                response.Headers.Add("Content-Type", "text/plain; charset=utf-8");
                await response.WriteStringAsync("The 'blobName' query parameter needs to be supplied.");

                return response;
            }

            try
            {
                var blobServiceClient = new BlobServiceClient(new Uri(_storageUri), new DefaultAzureCredential());
                var blobClient = blobServiceClient.GetBlobContainerClient(_containerName).GetBlobClient(blobName);

                using var downloadStream = new MemoryStream();
                await blobClient.DownloadToAsync(downloadStream);

                // Convert the content to a string
                string blobContent = Encoding.UTF8.GetString(downloadStream.ToArray());

                var response = req.CreateResponse(HttpStatusCode.OK);
                response.Headers.Add("Content-Type", "text/plain; charset=utf-8");
                await response.WriteStringAsync(blobContent);

                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError($"An error occurred: {ex.Message}");
                var response = req.CreateResponse(HttpStatusCode.InternalServerError);
                response.Headers.Add("Content-Type", "text/plain; charset=utf-8");
                response.WriteString($"An error occurred: {ex.Message}");
                return response;
            }
        }
    }
}
