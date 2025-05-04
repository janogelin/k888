# Terraform Kubernetes Provider Setup

This project demonstrates how to use the [Kubernetes provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs) for Terraform to manage resources on a local Kubernetes cluster using your `kubectl` configuration. It also includes example CI/CD scripts, developer command logs, and Kafka sizing documentation.

## Files and Directories

- **main.tf**: Terraform configuration for the Kubernetes provider, using your local kubeconfig (`~/.kube/config`).
- **.github/workflows/terraform-k8s-provider.yml**: GitHub Actions workflow to automate Terraform and Kubernetes setup in CI/CD.
- **terraform-k8s-provider.yml**: Standalone, generic CI/CD YAML script to set up Terraform and the Kubernetes provider using local kubeconfig. Adaptable for other CI/CD systems.
- **devcommand.log**: Example developer commands for working with Kubernetes and MySQL, such as running a MySQL client, executing into pods, and port-forwarding.
- **kafkaplan/**: Directory containing Kafka-related documentation and resources.
  - **kafka_sizing_requirements.md**: A markdown table summarizing recommended Kafka sizing parameters, including workload, throughput, replication, broker specs, retention, and scaling/monitoring.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed locally
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed and configured to access your local cluster
- A valid `~/.kube/config` file

## Usage

### Local Usage
1. Clone this repository.
2. Ensure your `kubectl` is configured and can access your local cluster:
   ```sh
   kubectl get nodes
   ```
3. Initialize Terraform:
   ```sh
   terraform init
   ```
4. Plan your changes:
   ```sh
   terraform plan
   ```
5. Apply your changes:
   ```sh
   terraform apply
   ```

### GitHub Actions Usage
1. Store your kubeconfig content as a repository secret named `KUBECONFIG_CONTENT`.
2. On push, the workflow in `.github/workflows/terraform-k8s-provider.yml` will:
   - Install Terraform and kubectl
   - Set up the kubeconfig
   - Run `terraform init` and `terraform plan`

### Standalone CI/CD Script Usage
- Use `terraform-k8s-provider.yml` as a template for your own CI/CD system (e.g., GitLab CI, Bitbucket Pipelines).
- Set the environment variable `KUBECONFIG_CONTENT` with your kubeconfig content.
- The script will:
  - Clone your repository
  - Install Terraform and kubectl
  - Configure kubeconfig
  - Run `terraform init` and `terraform plan`

### Developer Commands
- See `devcommand.log` for example commands to:
  - Nothing in here is secure just dev
  - Run a MySQL client pod in Kubernetes
  - Exec into MySQL or client pods
  - Port-forward MySQL service to localhost

### Kafka Sizing Requirements
- See `kafkaplan/kafka_sizing_requirements.md` for a comprehensive table of recommended Kafka sizing and configuration parameters, including:
  - Workload estimates (message size, producers, consumers, topics, partitions)
  - Throughput and storage calculations
  - Replication and broker specs
  - Retention, compaction, and scaling/monitoring best practices

## Notes
- The workflows and scripts assume your kubeconfig is compatible with the cluster you want to manage.
- For production, consider using a service account and limiting permissions in your kubeconfig.

## References
- [Terraform Kubernetes Provider Docs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [GitHub Actions: hashicorp/setup-terraform](https://github.com/hashicorp/setup-terraform)
- [GitHub Actions: azure/setup-kubectl](https://github.com/Azure/setup-kubectl) 