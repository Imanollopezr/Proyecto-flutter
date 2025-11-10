namespace PetLove.API.Services
{
    public interface ITokenService
    {
        /// <summary>
        /// Genera un token seguro para recuperación de contraseña
        /// </summary>
        string GeneratePasswordResetToken(int userId, string email);

        /// <summary>
        /// Genera un código de verificación de 6 dígitos para recuperación de contraseña
        /// </summary>
        string GenerateVerificationCode();

        /// <summary>
        /// Genera un token seguro para correo de bienvenida
        /// </summary>
        string GenerateWelcomeToken(int userId, string email);

        /// <summary>
        /// Valida un token de recuperación de contraseña
        /// </summary>
        bool ValidatePasswordResetToken(string token, int userId, string email);
    }
}