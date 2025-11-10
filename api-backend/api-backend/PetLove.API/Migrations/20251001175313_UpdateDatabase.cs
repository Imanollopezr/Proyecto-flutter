using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PetLove.API.Migrations
{
    /// <inheritdoc />
    public partial class UpdateDatabase : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "GananciaCalculada",
                table: "DetalleCompra",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "PorcentajeGanancia",
                table: "DetalleCompra",
                type: "decimal(5,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "GananciaCalculada",
                table: "Compras",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "PorcentajeGanancia",
                table: "Compras",
                type: "decimal(5,2)",
                nullable: false,
                defaultValue: 0m);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Soltar restricciones por defecto si existen (SQL Server autogenera nombres)
            migrationBuilder.Sql(@"
DECLARE @cn NVARCHAR(128);

-- DetalleCompra.GananciaCalculada
SELECT @cn = dc.name
FROM sys.default_constraints dc
JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
WHERE OBJECT_NAME(dc.parent_object_id) = 'DetalleCompra' AND c.name = 'GananciaCalculada';
IF @cn IS NOT NULL EXEC(N'ALTER TABLE [DetalleCompra] DROP CONSTRAINT [' + @cn + N']');

-- DetalleCompra.PorcentajeGanancia
SELECT @cn = dc.name
FROM sys.default_constraints dc
JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
WHERE OBJECT_NAME(dc.parent_object_id) = 'DetalleCompra' AND c.name = 'PorcentajeGanancia';
IF @cn IS NOT NULL EXEC(N'ALTER TABLE [DetalleCompra] DROP CONSTRAINT [' + @cn + N']');

-- Compras.GananciaCalculada
SELECT @cn = dc.name
FROM sys.default_constraints dc
JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
WHERE OBJECT_NAME(dc.parent_object_id) = 'Compras' AND c.name = 'GananciaCalculada';
IF @cn IS NOT NULL EXEC(N'ALTER TABLE [Compras] DROP CONSTRAINT [' + @cn + N']');

-- Compras.PorcentajeGanancia
SELECT @cn = dc.name
FROM sys.default_constraints dc
JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
WHERE OBJECT_NAME(dc.parent_object_id) = 'Compras' AND c.name = 'PorcentajeGanancia';
IF @cn IS NOT NULL EXEC(N'ALTER TABLE [Compras] DROP CONSTRAINT [' + @cn + N']');
");

            migrationBuilder.DropColumn(
                name: "GananciaCalculada",
                table: "DetalleCompra");

            migrationBuilder.DropColumn(
                name: "PorcentajeGanancia",
                table: "DetalleCompra");

            migrationBuilder.DropColumn(
                name: "GananciaCalculada",
                table: "Compras");

            migrationBuilder.DropColumn(
                name: "PorcentajeGanancia",
                table: "Compras");
        }
    }
}
