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
│   ├── key-vault/
│   └── storage-account/
│
└── stacks/
    └── example-deployment/
        └── main.tf
```

- **`/modules`**: Este directorio contiene todos los módulos de Terraform reutilizables. Cada subdirectorio corresponde a un módulo específico. Los módulos actualmente disponibles son:
    - `data-factory`: Para desplegar Azure Data Factory con soporte para Private Endpoints.
    - `databricks-workspace`: Para desplegar un workspace de Azure Databricks con VNet Injection y Private Link.
    - `key-vault`: Para desplegar Azure Key Vault con gestión de políticas de acceso y Private Endpoint.
    - `storage-account`: Para desplegar Azure Storage Accounts, con soporte para Data Lake Gen2 y Private Endpoints para `blob`, `file`, `queue` y `dfs`.

- **`/stacks`**: Este directorio contiene las configuraciones de nivel superior o "stacks". Cada subdirectorio representa un despliegue de infraestructura completo y coherente.
    - `example-deployment`: Un stack de ejemplo que muestra cómo consumir los módulos `storage-account` y `key-vault`.

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
