# Repositorio de Infraestructura como Código (IaC) para Azure

Este repositorio contiene el código de Terraform para gestionar la infraestructura en Azure, siguiendo los principios de Infraestructura como Código (IaC). Está diseñado para ser modular, reutilizable y escalable.

## Filosofía

El código en este repositorio se adhiere a las siguientes prácticas:

- **Modularidad**: La infraestructura se define en módulos reutilizables que encapsulan una funcionalidad específica (ej. un workspace de Databricks, una Data Factory).
- **Reutilización**: Los módulos están diseñados para ser agnósticos al entorno y pueden ser consumidos por diferentes proyectos o "stacks".
- **Stacks (Pilas)**: Las configuraciones específicas de un entorno o proyecto (desarrollo, producción, etc.) se definen como "stacks". Cada stack consume uno o más módulos para desplegar un conjunto coherente de recursos.
- **Gestión de Estado Remoto**: El estado de Terraform se almacena de forma remota en un backend de Azure Storage para permitir la colaboración y el trabajo en equipo de forma segura.

## Estructura del Repositorio

El repositorio está organizado de la siguiente manera:

```
.
├── modules/
│   ├── data-factory/
│   ├── databricks-workspace/
│   ├── storage-account/
│   ├── keyvault/
│   └── sql-database/
│
└── stacks/
    └── (ejemplos: tenant-produccion, proyecto-cliente-x, etc.)
```

- **`/modules`**: Este directorio contiene todos los módulos de Terraform reutilizables. Cada subdirectorio corresponde a un módulo específico.
  - `main.tf`: Contiene la lógica principal y la definición de recursos del módulo.
  - `variables.tf`: Define las variables de entrada que el módulo acepta.
  - `outputs.tf`: Define los valores de salida que el módulo expone.

- **`/stacks`**: Este directorio contiene las configuraciones de nivel superior o "stacks". Cada subdirectorio representa un despliegue de infraestructura completo y coherente (por ejemplo, un entorno, un proyecto). Los archivos `main.tf` dentro de un stack hacen referencia a los módulos en el directorio `/modules` para aprovisionar los recursos.

## Flujo de Trabajo (Workflow)

El flujo de trabajo estándar para utilizar este repositorio es el siguiente:

1.  **Inicialización**: Navegar al directorio del stack que se desea desplegar y ejecutar `terraform init`. Esto descargará los proveedores necesarios y configurará el backend.

    ```bash
    cd stacks/<nombre-del-stack>
    terraform init
    ```

2.  **Planificación**: Ejecutar `terraform plan` para previsualizar los cambios que se aplicarán a la infraestructura. Es crucial revisar la salida de este comando antes de continuar.

    ```bash
    terraform plan
    ```

3.  **Aplicación**: Si el plan es correcto, ejecutar `terraform apply` para aprovisionar o actualizar la infraestructura en Azure.

    ```bash
    terraform apply
    ```

4.  **Destrucción**: Para eliminar todos los recursos gestionados por un stack, ejecutar `terraform destroy`.

    ```bash
    terraform destroy
    ```

## Cómo Empezar

Para crear un nuevo despliegue de infraestructura:

1.  Crea un nuevo subdirectorio dentro de la carpeta `/stacks`.
2.  Dentro de este nuevo directorio, crea un archivo `main.tf`.
3.  En `main.tf`, define la configuración del backend de Terraform (generalmente Azure Storage).
4.  Utiliza la palabra clave `module` para invocar a los módulos necesarios desde el directorio `/modules`, proporcionando los valores requeridos para las variables.
5.  Sigue el flujo de trabajo descrito anteriormente para desplegar tu infraestructura.

## Capacidades y mejores prácticas

### Private Endpoints con IP estática por offset (cidrhost)

- Todos los módulos soportan asignar IP estática a los Private Endpoints de dos formas:
  - IP literal: `*_private_endpoint_ip_address = "10.10.0.10"`
  - Offset: `*_private_endpoint_ip_offset = 10` que se convierte con `cidrhost(subnet_cidr, offset)`.
- Recomendación: definir un catálogo de offsets por servicio (p.ej., ADF=10, DBW=11, SA=12, KV=13, SQL=14) para evitar colisiones.
- Los módulos exigen IP fija/offset por defecto (`require_static_private_endpoint_ip = true`), fallando temprano si no se define.

### DNS privado

- Los módulos de ADF y Databricks integran Private DNS opcional; se recomienda habilitarlo (`enable_private_dns_integration = true`).

### Storage Account (ADLS Gen2 y PEs a demanda)

- `is_hns_enabled = true` habilita ADLS Gen2.
- Private Endpoints a demanda con `private_endpoint_subresources`, e.g. `["blob", "file", "dfs"]`.
- Reglas públicas: `network_rules` con `default_action = "Deny"` y `allowed_public_ips` para permitir solo IPs definidas.

### Key Vault

- Private Endpoint opcional y `network_acls` con `allowed_public_ips` si `public_network_access_enabled = true`.

### SQL Database

- Despliega `azurerm_mssql_server` y `azurerm_mssql_database`.
- Azure AD (Entra ID) admin: `sql_admin_group_object_id`, `sql_admin_group_name`, `azuread_authentication_only`.
- Private Endpoint con IP fija u offset y firewall opcional via `allowed_public_ips`.

## Estrategia de módulos y stacks (workspaces)

- Versionar módulos con tags semánticos y consumirlos desde stacks con `?ref=vX.Y.Z` o Registry privado.
- Workspaces por stack/ambiente: `<stack>-dev`, `<stack>-qa`, `<stack>-prod`. Variables sensibles en el workspace.
- Monorepo (módulos+stacks) recomendado al inicio. Al escalar, separar:
  - Repo módulos (solo reusable), Repo(s) stacks (por dominio/cliente).
- Governance: Azure Policy/OPA para exigir PEs y controlar accesos públicos.
