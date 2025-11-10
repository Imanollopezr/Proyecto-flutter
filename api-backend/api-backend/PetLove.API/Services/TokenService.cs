using Microsoft.AspNetCore.WebUtilities;
using System.Security.Cryptography;
using System.Text;

namespace PetLove.API.Services
{
    public class TokenService : ITokenService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<TokenService> _logger;
        private readonly string _secretKey;
        private readonly int _tokenExpirationMinutes;

        public TokenService(IConfiguration configuration, ILogger<TokenService> logger)
        {
            _configuration = configuration;
            _logger = logger;
            
            // Obtener clave secreta de la configuración o usar una predeterminada segura
            _secretKey = _configuration["TokenSettings:SecretKey"] ?? 
                         "PetLove_SecureTokenKey_2024_HMACSHA256_AuthenticationSystem";
            
            // Obtener tiempo de expiración de la configuración o usar valor predeterminado
            if (!int.TryParse(_configuration["TokenSettings:ExpirationMinutes"], out _tokenExpirationMinutes))
            {
                _tokenExpirationMinutes = 60; // 1 hora por defecto
            }
        }

        /// <summary>
        /// Genera un token seguro para recuperación de contraseña
        /// </summary>
        public string GeneratePasswordResetToken(int userId, string email)
        {
            try
            {
                // Crear datos para el token: userId + email + timestamp + salt aleatorio
                var timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString();
                var randomSalt = GenerateRandomString(16);
                var tokenData = $"{userId}:{email.ToLower()}:{timestamp}:{randomSalt}";

                // Generar firma HMAC-SHA256
                var signature = GenerateHmacSignature(tokenData);

                // Combinar datos y firma
                var tokenPayload = $"{tokenData}:{signature}";

                // Codificar en Base64Url para uso seguro en URLs
                return WebEncoders.Base64UrlEncode(Encoding.UTF8.GetBytes(tokenPayload));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al generar token de recuperación de contraseña para usuario {UserId}", userId);
                throw new InvalidOperationException("No se pudo generar el token de seguridad", ex);
            }
        }

        /// <summary>
        /// Genera un código de verificación de 6 dígitos para recuperación de contraseña
        /// </summary>
        public string GenerateVerificationCode()
        {
            // Generar código numérico aleatorio de 6 dígitos
            using var rng = RandomNumberGenerator.Create();
            var randomNumber = new byte[4];
            rng.GetBytes(randomNumber);
            var value = BitConverter.ToUInt32(randomNumber, 0);
            
            // Asegurar que sea exactamente 6 dígitos
            return (value % 900000 + 100000).ToString();
        }

        /// <summary>
        /// Genera un token seguro para correo de bienvenida
        /// </summary>
        public string GenerateWelcomeToken(int userId, string email)
        {
            try
            {
                // Similar al token de recuperación pero con propósito diferente
                var timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString();
                var randomSalt = GenerateRandomString(16);
                var purpose = "welcome";
                var tokenData = $"{userId}:{email.ToLower()}:{timestamp}:{randomSalt}:{purpose}";

                // Generar firma HMAC-SHA256
                var signature = GenerateHmacSignature(tokenData);

                // Combinar datos y firma
                var tokenPayload = $"{tokenData}:{signature}";

                // Codificar en Base64Url para uso seguro en URLs
                return WebEncoders.Base64UrlEncode(Encoding.UTF8.GetBytes(tokenPayload));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al generar token de bienvenida para usuario {UserId}", userId);
                throw new InvalidOperationException("No se pudo generar el token de bienvenida", ex);
            }
        }

        /// <summary>
        /// Valida un token de recuperación de contraseña
        /// </summary>
        public bool ValidatePasswordResetToken(string token, int userId, string email)
        {
            try
            {
                // Decodificar token
                var tokenBytes = WebEncoders.Base64UrlDecode(token);
                var tokenPayload = Encoding.UTF8.GetString(tokenBytes);

                // Separar datos y firma
                var parts = tokenPayload.Split(':');
                if (parts.Length != 5) // userId, email, timestamp, salt, signature
                {
                    _logger.LogWarning("Formato de token inválido");
                    return false;
                }

                // Extraer componentes
                var tokenUserId = int.Parse(parts[0]);
                var tokenEmail = parts[1];
                var timestamp = long.Parse(parts[2]);
                var salt = parts[3];
                var signature = parts[4];

                // Verificar que el token corresponde al usuario correcto
                if (tokenUserId != userId || tokenEmail.ToLower() != email.ToLower())
                {
                    _logger.LogWarning("Token no corresponde al usuario {UserId}", userId);
                    return false;
                }

                // Verificar que el token no ha expirado
                var tokenTime = DateTimeOffset.FromUnixTimeSeconds(timestamp);
                var expirationTime = tokenTime.AddMinutes(_tokenExpirationMinutes);
                if (DateTimeOffset.UtcNow > expirationTime)
                {
                    _logger.LogWarning("Token expirado para usuario {UserId}", userId);
                    return false;
                }

                // Reconstruir datos para verificar firma
                var tokenData = $"{tokenUserId}:{tokenEmail}:{timestamp}:{salt}";
                var expectedSignature = GenerateHmacSignature(tokenData);

                // Comparar firmas (tiempo constante para evitar timing attacks)
                return CryptographicOperations.FixedTimeEquals(
                    Encoding.UTF8.GetBytes(signature),
                    Encoding.UTF8.GetBytes(expectedSignature));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al validar token para usuario {UserId}", userId);
                return false;
            }
        }

        #region Métodos privados

        /// <summary>
        /// Genera una firma HMAC-SHA256 para los datos proporcionados
        /// </summary>
        private string GenerateHmacSignature(string data)
        {
            using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(_secretKey));
            var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(data));
            return Convert.ToHexString(hash).ToLower();
        }

        /// <summary>
        /// Genera una cadena aleatoria del tamaño especificado
        /// </summary>
        private string GenerateRandomString(int length)
        {
            const string chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            var random = new byte[length];
            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(random);
            
            var result = new StringBuilder(length);
            foreach (var b in random)
            {
                result.Append(chars[b % chars.Length]);
            }
            
            return result.ToString();
        }

        #endregion
    }
}