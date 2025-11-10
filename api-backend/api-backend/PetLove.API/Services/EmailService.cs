using SendGrid;
using SendGrid.Helpers.Mail;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace PetLove.API.Services
{
    public interface IEmailService
    {
        Task<bool> SendPasswordResetEmailAsync(string toEmail, string userName, string resetToken);
        Task<bool> SendPasswordResetCodeAsync(string toEmail, string userName, string code);
        Task<bool> SendWelcomeEmailAsync(string toEmail, string userName, string? activationToken = null);
    }

    public class EmailService : IEmailService
    {
        private readonly ISendGridClient _sendGridClient;
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;
        private readonly string _fromEmail;
        private readonly string _fromName;
        private readonly string _frontendUrl;
        private readonly string _templateWelcomeId;
        private readonly string _templateVerificationCodeId;
        private readonly string _templatePasswordResetId;

        public EmailService(ISendGridClient sendGridClient, IConfiguration configuration, ILogger<EmailService> logger)
        {
            _sendGridClient = sendGridClient;
            _configuration = configuration;
            _logger = logger;
            _fromEmail = _configuration["SendGrid:FromEmail"] ?? "noreply@petlove.com";
            _fromName = _configuration["SendGrid:FromName"] ?? "PetLove";
            _frontendUrl = _configuration["Frontend:BaseUrl"] ?? "http://localhost:5174";
            _templateWelcomeId = _configuration["SendGrid:Templates:Welcome"] ?? string.Empty;
            _templateVerificationCodeId = _configuration["SendGrid:Templates:VerificationCode"] ?? string.Empty;
            _templatePasswordResetId = _configuration["SendGrid:Templates:PasswordReset"] ?? string.Empty;
        }

        public async Task<bool> SendPasswordResetEmailAsync(string toEmail, string userName, string resetToken)
        {
            try
            {
                var from = new EmailAddress(_fromEmail, _fromName);
                var to = new EmailAddress(toEmail, userName);
                var subject = "Recuperación de Contraseña - PetLove";

                var resetUrl = $"{_frontendUrl}/reset-password?token={resetToken}";

                var htmlContent = GetPasswordResetHtmlTemplate(userName, resetUrl);
                var plainTextContent = GetPasswordResetPlainTextTemplate(userName, resetUrl);

                var msg = MailHelper.CreateSingleEmail(from, to, subject, plainTextContent, htmlContent);

                msg.SetReplyTo(new EmailAddress(_fromEmail, _fromName));
                msg.AddCategory("password-reset");
                msg.AddCustomArg("type", "password-reset");

                msg.SetClickTracking(false, false);
                msg.SetOpenTracking(false);
                msg.SetSubscriptionTracking(false);

                var response = await _sendGridClient.SendEmailAsync(msg);

                string responseBody = string.Empty;
                try
                {
                    responseBody = response.Body != null ? await response.Body.ReadAsStringAsync() : string.Empty;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "No se pudo leer el cuerpo de la respuesta de SendGrid (password reset)");
                }

                _logger.LogInformation("SendGrid (password reset) status: {Status} body: {Body}", response.StatusCode, responseBody);

                if (response.StatusCode == System.Net.HttpStatusCode.Accepted)
                {
                    _logger.LogInformation("Email de recuperación enviado exitosamente a {Email}", toEmail);
                    return true;
                }
                else
                {
                    _logger.LogError("Error al enviar email de recuperación a {Email}. Status: {Status}", toEmail, response.StatusCode);
                    return false;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Excepción al enviar email de recuperación a {Email}", toEmail);
                return false;
            }
        }

        public async Task<bool> SendPasswordResetCodeAsync(string toEmail, string userName, string code)
        {
            try
            {
                var from = new EmailAddress(_fromEmail, _fromName);
                var to = new EmailAddress(toEmail, userName);
                var subject = "Código de verificación - PetLove";

                var htmlContent = GetPasswordResetCodeHtmlTemplate(userName, code);
                var plainTextContent = GetPasswordResetCodePlainTextTemplate(userName, code);

                var msg = MailHelper.CreateSingleEmail(from, to, subject, plainTextContent, htmlContent);

                msg.SetReplyTo(new EmailAddress(_fromEmail, _fromName));
                msg.AddCategory("verification-code");
                msg.AddCustomArg("type", "verification-code");

                msg.SetClickTracking(false, false);
                msg.SetOpenTracking(false);
                msg.SetSubscriptionTracking(false);

                var response = await _sendGridClient.SendEmailAsync(msg);

                string responseBody = string.Empty;
                try
                {
                    responseBody = response.Body != null ? await response.Body.ReadAsStringAsync() : string.Empty;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "No se pudo leer el cuerpo de la respuesta de SendGrid (verification code)");
                }

                _logger.LogInformation("SendGrid (verification code) status: {Status} body: {Body}", response.StatusCode, responseBody);

                if (response.StatusCode == System.Net.HttpStatusCode.Accepted)
                {
                    _logger.LogInformation("Código de verificación enviado exitosamente a {Email}", toEmail);
                    return true;
                }
                else
                {
                    _logger.LogError("Error al enviar código de verificación a {Email}. Status: {Status}", toEmail, response.StatusCode);
                    return false;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Excepción al enviar código de verificación a {Email}", toEmail);
                return false;
            }
        }

        public async Task<bool> SendWelcomeEmailAsync(string toEmail, string userName, string? activationToken = null)
        {
            try
            {
                // Generar contenido sin enlace ni botón de activación
                var htmlContent = GetWelcomeHtmlTemplate(userName);
                var plainTextContent = GetWelcomePlainTextTemplate(userName);

                var from = new EmailAddress(_fromEmail, _fromName);
                var to = new EmailAddress(toEmail, userName);
                var subject = "¡Bienvenido a PetLove! Tu cuenta ya está lista";

                var msg = MailHelper.CreateSingleEmail(from, to, subject, plainTextContent, htmlContent);
                msg.SetReplyTo(new EmailAddress(_fromEmail, _fromName));
                msg.AddCategory("welcome");
                msg.AddCustomArg("type", "welcome");
                msg.SetClickTracking(false, false);
                msg.SetOpenTracking(false);
                msg.SetSubscriptionTracking(false);

                var response = await _sendGridClient.SendEmailAsync(msg);

                string responseBody = string.Empty;
                try
                {
                    responseBody = response.Body != null ? await response.Body.ReadAsStringAsync() : string.Empty;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "No se pudo leer el cuerpo de la respuesta de SendGrid (welcome)");
                }

                _logger.LogInformation("SendGrid (welcome) status: {Status} body: {Body}", response.StatusCode, responseBody);

                if (response.StatusCode == System.Net.HttpStatusCode.Accepted)
                {
                    _logger.LogInformation("Email de bienvenida enviado exitosamente a {Email}", toEmail);
                    return true;
                }
                else
                {
                    _logger.LogError("Error al enviar email de bienvenida a {Email}. Status: {Status}", toEmail, response.StatusCode);
                    return false;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Excepción al enviar email de bienvenida a {Email}", toEmail);
                return false;
            }
        }

        private IEnumerable<string> MapModules(IEnumerable<string> permissions)
        {
            var map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                { "GestionRoles", "Gestión de Roles" },
                { "GestionUsuarios", "Gestión de Usuarios" },
                { "VerDashboard", "Dashboard" },
                { "GestionClientes", "Gestión de Clientes" },
                { "GestionProveedores", "Gestión de Proveedores" },
                { "GestionCategorias", "Gestión de Categorías" },
                { "GestionMarcas", "Gestión de Marcas" },
                { "GestionMedidas", "Gestión de Medidas" },
                { "GestionProductos", "Gestión de Productos" },
                { "GestionCompras", "Gestión de Compras" },
                { "GestionVentas", "Gestión de Ventas" }
            };

            var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var p in permissions)
            {
                if (string.IsNullOrWhiteSpace(p)) continue;
                if (map.TryGetValue(p.Trim(), out var friendly))
                {
                    set.Add(friendly);
                }
                else
                {
                    var words = System.Text.RegularExpressions.Regex.Replace(p.Trim(), "([a-z])([A-Z])", "$1 $2");
                    set.Add(words);
                }
            }
            var list = new List<string>(set);
            list.Sort(StringComparer.OrdinalIgnoreCase);
            return list;
        }

        private string GetPasswordResetCodeHtmlTemplate(string userName, string code)
        {
            return $@"
<!DOCTYPE html>
<html lang=""es"">
<head>
  <meta charset=""UTF-8"">
  <meta name=""viewport"" content=""width=device-width, initial-scale=1.0"">
  <title>Tu código de verificación</title>
</head>
<body style=""margin:0; padding:0; background-color:#f7f7f7; font-family: Inter, Arial, sans-serif; color:#333;"">
  <div style=""max-width:600px; margin:0 auto; background:#ffffff; border-radius:12px; overflow:hidden; box-shadow:0 10px 30px rgba(0,0,0,0.06);"">
    <div style=""background: linear-gradient(135deg, #F5A623 0%, #FFD54F 100%); width:100%; padding:24px; text-align:center; color:#ffffff;"">
      <span style=""font-weight:600; font-size:18px; vertical-align:middle;"">PetLove</span>
      <div style=""font-size:14px; margin-top:6px; opacity:0.95;"">Tu código de verificación está listo</div>
    </div>
    <div style=""padding:32px;"">
      <p style=""margin:0 0 16px 0;"">Hola {userName},</p>
      <p style=""margin:0 0 24px 0;"">Para continuar de forma segura, utiliza el siguiente código:</p>
      <div style=""display:inline-block; background: linear-gradient(135deg, #F5A623 0%, #FFD54F 100%); color:#ffffff; padding:14px 26px; border-radius:10px; font-weight:700; font-size:24px; letter-spacing:6px; text-align:center; box-shadow:0 10px 25px rgba(245, 166, 35, 0.35);"">
        {code}
      </div>
      <div style=""background:#fff8e1; border-left:4px solid #F5A623; padding:14px 16px; border-radius:8px; margin-top:24px; color:#5d4037;"">
        <strong style=""color:#F5A623;"">Información importante:</strong>
        <ul style=""padding-left:20px; margin:10px 0 0 0;"">
          <li>Este código expira en 10 minutos por seguridad.</li>
          <li>No compartas este código con nadie.</li>
        </ul>
      </div>
    </div>
    <div style=""padding:16px 24px; text-align:center; font-size:12px; color:#999;"">
      © {DateTime.UtcNow.Year} PetLove. Todos los derechos reservados.
    </div>
  </div>
</body>
</html>";
        }

        private string GetPasswordResetCodePlainTextTemplate(string userName, string code)
        {
            return $@"¡Hola {userName}!

Hemos recibido una solicitud para acceder a tu cuenta de PetLove.

Para continuar de forma segura, utiliza el siguiente código de verificación: {code}

Información importante:
- Este código es válido por 1 hora únicamente.
- Si no realizaste esta solicitud, puedes ignorar este mensaje de forma segura.

Si tienes alguna pregunta o necesitas ayuda, no dudes en contactarnos. Estamos aquí para ayudarte.

¡Gracias por elegir PetLove!
El equipo de PetLove

© {DateTime.UtcNow.Year} PetLove. Todos los derechos reservados.
Este correo fue enviado a tu dirección de correo. Si no solicitaste esta recuperación, puedes ignorar este mensaje.";
        }

        private string GetPasswordResetHtmlTemplate(string userName, string resetUrl)
        {
            return $@"
<!DOCTYPE html>
<html lang=""es"">
<head>
  <meta charset=""utf-8"">
  <meta name=""viewport"" content=""width=device-width,initial-scale=1"">
  <title>Restablecer contraseña</title>
</head>
<body style=""margin:0;padding:24px;background:#f6f7f9;font-family:Arial,Helvetica,sans-serif;color:#222;"">
  <div style=""max-width:520px;margin:0 auto;background:#fff;border:1px solid #e4e6eb;border-radius:8px;overflow:hidden;"">
    <div style=""background:#ffeb3b;color:#222;padding:16px;font-weight:bold;text-align:center"">
      Restablecer contraseña
    </div>
    <div style=""padding:24px"">
      <p style=""margin:0 0 12px"">Hola {userName},</p>
      <p style=""margin:0 0 16px"">
        Has solicitado cambiar tu contraseña. Haz clic en el siguiente botón:
      </p>
      <p style=""text-align:center;margin:24px 0"">
        <a href=""{resetUrl}"" style=""display:inline-block;background:#1976d2;color:#fff;text-decoration:none;padding:12px 20px;border-radius:6px"">
          Ir a restablecer contraseña
        </a>
      </p>
      <p style=""margin:16px 0 0;font-size:12px;color:#666"">
        Si no solicitaste este cambio, ignora este correo.
      </p>
    </div>
  </div>
</body>
</html>";
        }

        private string GetPasswordResetPlainTextTemplate(string userName, string resetUrl)
        {
            return $@"Hola {userName},

Has solicitado restablecer tu contraseña en PetLove.
Si no fuiste tú, puedes ignorar este mensaje.

Enlace para restablecer:
{resetUrl}

Validez del enlace: 1 hora.

¿Necesitas ayuda? Visita: {_frontendUrl}/contacto

Equipo de PetLove
© {DateTime.UtcNow.Year} PetLove. Todos los derechos reservados.";
        }

        private string GetWelcomeHtmlTemplate(string userName, string? activationUrl = null)
        {
            // Ignoramos activationUrl y no renderizamos botón ni enlaces
            var startUrl = _frontendUrl?.TrimEnd('/') ?? "https://petlove.example";
            return $@"
<!DOCTYPE html>
<html lang='es'>
<head>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'>
  <title>¡Bienvenido a PetLove!</title>
  <style>
    body {{ margin:0; padding:24px; background:#f2f4f7; font-family:Segoe UI, Tahoma, Geneva, Verdana, sans-serif; color:#2b2d31; }}
    .card {{ max-width:600px; margin:0 auto; background:#fff; border-radius:16px; box-shadow:0 8px 24px rgba(0,0,0,0.08); overflow:hidden; }}
    .header {{ background:linear-gradient(135deg,#FCC52C 0%,#F5A623 100%); padding:28px 24px; text-align:center; }}
    .header h1 {{ margin:0; font-size:28px; color:#1f2328; }}
    .content {{ padding:24px; }}
    .greeting {{ font-size:18px; margin:0 0 8px; }}
    .message {{ font-size:15px; line-height:1.7; margin:0 0 16px; color:#4c5159; }}
    .list {{ margin:12px 0; padding-left:18px; color:#4c5159; }}
    .cta {{ text-align:center; margin:24px 0; }}
    .cta a {{ display:inline-block; background:#1f2328; color:#fff; text-decoration:none; padding:12px 20px; border-radius:8px; }}
    .note {{ font-size:13px; color:#6b7280; margin-top:12px; }}
    .footer {{ text-align:center; font-size:12px; color:#98a1b2; padding:16px; background:#f8f9fa; }}
  </style>
</head>
<body>
  <div class='card'>
    <div class='header'>
      <h1>¡Bienvenido a PetLove!</h1>
    </div>
    <div class='content'>
      <p class='greeting'>¡Hola {userName}!</p>
      <p class='message'>
        Nos encanta tenerte aquí. Tu cuenta ya está lista y puedes empezar a
        descubrir productos, consejos y todo lo que necesitas para cuidar con amor
        a tu mejor amigo.
      </p>
      <p class='message'><strong>¿Qué puedes hacer ahora?</strong></p>
      <ul class='list'>
        <li>Completar tu perfil para personalizar recomendaciones.</li>
        <li>Explorar productos esenciales y ofertas destacadas.</li>
        <li>Seguir tus pedidos y ver tu historial de compras.</li>
        <li>Contactar soporte si necesitas ayuda.</li>
      </ul>
      <div class='cta'>
        <a href='{startUrl}' target='_blank' rel='noopener'>Empezar en PetLove</a>
        <div class='note'>Si el botón no funciona, copia y pega este enlace en tu navegador: {startUrl}</div>
      </div>
      <p class='message'>
        ¿Necesitas ayuda? Escríbenos a <a href='mailto:{_fromEmail}'>{_fromEmail}</a>. Estamos aquí para ayudarte.
      </p>
    </div>
    <div class='footer'>
      <p>© {DateTime.UtcNow.Year} PetLove. Todos los derechos reservados.</p>
    </div>
  </div>
</body>
</html>";
        }

        private string GetWelcomePlainTextTemplate(string userName, string? activationUrl = null)
        {
            // Sin texto de activación
            var startUrl = _frontendUrl?.TrimEnd('/') ?? "https://petlove.example";
            return $@"¡Bienvenido a PetLove, {userName}!

Nos encanta tenerte aquí. Tu cuenta ya está lista para usarse.

¿Qué puedes hacer ahora?
- Completar tu perfil para personalizar recomendaciones.
- Explorar productos esenciales y ofertas destacadas.
- Seguir tus pedidos y ver tu historial de compras.
- Contactar soporte si necesitas ayuda.

Empieza en PetLove: {startUrl}
Si el botón del correo no funciona, copia y pega el enlace anterior en tu navegador.

¿Necesitas ayuda? Escríbenos a {_fromEmail}. Estamos aquí para ayudarte.

© {DateTime.UtcNow.Year} PetLove. Todos los derechos reservados.";
        }
    }
}