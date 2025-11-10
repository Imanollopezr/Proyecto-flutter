using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PetLove.API.Migrations
{
    /// <inheritdoc />
    public partial class SyncUsuariosSchema : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "FotoPerfilUrl",
                table: "Usuarios",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ImagenUrl",
                table: "CATEGORIA_PRODUCTO",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "FotoPerfilUrl",
                table: "Usuarios");

            migrationBuilder.DropColumn(
                name: "ImagenUrl",
                table: "CATEGORIA_PRODUCTO");
        }
    }
}
