using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SendGrid;
using System.Text.Json;

namespace PetLove.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SendGridController : ControllerBase
    {
        private readonly ISendGridClient _sendGridClient;
        private readonly ILogger<SendGridController> _logger;

        public SendGridController(ISendGridClient sendGridClient, ILogger<SendGridController> logger)
        {
            _sendGridClient = sendGridClient;
            _logger = logger;
        }

        [HttpGet("details")]
        [Authorize]
        public async Task<IActionResult> GetDetails()
        {
            async Task<object?> ReadJsonAsync(Response response, string label)
            {
                string body = string.Empty;
                try
                {
                    body = response.Body != null ? await response.Body.ReadAsStringAsync() : string.Empty;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "No se pudo leer la respuesta de SendGrid para {Label}", label);
                }

                if (string.IsNullOrWhiteSpace(body))
                    return null;

                try
                {
                    using var doc = JsonDocument.Parse(body);
                    return doc.RootElement.Clone();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "No se pudo parsear JSON de {Label}. Body: {Body}", label, body);
                    return new { raw = body };
                }
            }

            var accountResp = await _sendGridClient.RequestAsync(SendGridClient.Method.GET, "user/account");
            var accountJson = await ReadJsonAsync(accountResp, "user/account");

            var trackingResp = await _sendGridClient.RequestAsync(SendGridClient.Method.GET, "tracking_settings");
            var trackingJson = await ReadJsonAsync(trackingResp, "tracking_settings");

            var mailResp = await _sendGridClient.RequestAsync(SendGridClient.Method.GET, "mail_settings");
            var mailJson = await ReadJsonAsync(mailResp, "mail_settings");

            var startDate = DateTime.UtcNow.AddDays(-7).ToString("yyyy-MM-dd");
            var endDate = DateTime.UtcNow.ToString("yyyy-MM-dd");
            var statsEndpoint = $"stats?start_date={startDate}&end_date={endDate}&aggregated_by=day";
            var statsResp = await _sendGridClient.RequestAsync(SendGridClient.Method.GET, statsEndpoint);
            var statsJson = await ReadJsonAsync(statsResp, "stats");

            var keysResp = await _sendGridClient.RequestAsync(SendGridClient.Method.GET, "api_keys");
            var keysJson = await ReadJsonAsync(keysResp, "api_keys");

            var payload = new
            {
                account = accountJson,
                tracking_settings = trackingJson,
                mail_settings = mailJson,
                api_keys = keysJson,
                stats_last_7_days = statsJson
            };

            return Ok(payload);
        }
    }
}