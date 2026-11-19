# tomcatdeploy

A Tomcat WAR app, deployed to Amazon EKS with Wiz security at every stage:

| Stage | What Wiz does | Where |
|---|---|---|
| Code | IaC scan of `Dockerfile` and `k8s/` manifests | CI: `wizcli iac scan` |
| Build | Vulnerability/secret/malware scan of the image; a policy failure stops the pipeline | CI: `wizcli docker scan` |
| Registry | Image is tagged in Wiz so it's linked to code/CI in the Security Graph | CI: `wizcli docker tag` |
| Deploy | Admission controller enforces Wiz policies on what runs | `wiz/` Helm chart |
| Runtime | Connector (posture) + Sensor (runtime threat detection) | `wiz/` Helm chart |

## Layout

- `Dockerfile`: multi-stage build (Maven → Tomcat 10.1 / JRE 17), runs as non-root UID 10001
- `k8s/`: Kustomize manifests (Namespace, Deployment, Service, ALB Ingress)
- `.github/workflows/eks-wiz-deploy.yml`: build → Wiz scans → push to ECR → deploy to EKS (PRs only build and scan)
- `wiz/`: Wiz Kubernetes Integration Helm values and install script

## One-time setup

1. **EKS cluster** with the [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/) installed (for the ALB Ingress).
2. **ECR repository**, e.g. `tomcatdeploy`.
3. **GitHub OIDC role** in AWS that can push to ECR and run `eks:DescribeCluster`. Map it into the cluster (EKS access entry or `aws-auth`) with rights to deploy into the `tomcatdeploy` namespace.
4. **Wiz service account** (Settings → Service Accounts) with the scopes `create:security_scans` and `update:security_scans`. Add a separate Kubernetes-integration service account for the cluster.
5. **GitHub repo settings**
   - Secrets: `WIZ_CLIENT_ID`, `WIZ_CLIENT_SECRET`, `AWS_ROLE_ARN`
   - Variables: `AWS_REGION`, `ECR_REPOSITORY`, `EKS_CLUSTER_NAME`, and optionally `WIZ_IAC_POLICY` and `WIZ_VULN_POLICY` (names of policies in your Wiz tenant)
6. **Wiz in the cluster**:
   ```bash
   aws eks update-kubeconfig --name <cluster> --region <region>
   export WIZ_CLIENT_ID=... WIZ_CLIENT_SECRET=... WIZ_SENSOR_PULL_USER=... WIZ_SENSOR_PULL_PASSWORD=...
   ./wiz/install.sh
   ```

## Local run

```bash
docker build -t tomcatdeploy .
docker run --rm -p 8080:8080 tomcatdeploy   # http://localhost:8080/
```
