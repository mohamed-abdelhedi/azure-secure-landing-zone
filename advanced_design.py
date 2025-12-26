from diagrams import Diagram, Cluster, Edge
from diagrams.azure.network import Firewall, VirtualNetworks, VirtualNetworkGateways, RouteTables, PrivateEndpoint, ApplicationGateway, TrafficManagerProfiles, FrontDoors
from diagrams.azure.compute import VM, VMScaleSets, ContainerInstances, KubernetesServices
from diagrams.azure.database import SQLDatabases, CosmosDb
from diagrams.azure.security import Sentinel, KeyVaults, Defender, ApplicationSecurityGroups
from diagrams.azure.managementgovernance import LogAnalyticsWorkspaces, Monitor, Policy
from diagrams.azure.general import CostManagement
from diagrams.azure.devops import Pipelines, Repos
from diagrams.azure.identity import ManagedIdentities, ActiveDirectory
from diagrams.azure.storage import BlobStorage
from diagrams.azure.ml import MachineLearningServiceWorkspaces
from diagrams.onprem.network import Internet
from diagrams.onprem.compute import Server
from diagrams.programming.language import Python

graph_attr = {
    "fontsize": "18",
    "bgcolor": "white",
    "splines": "ortho",
    "pad": "0.8",
    "nodesep": "0.8",
    "ranksep": "1.2"
}

with Diagram(
    "AI-Powered Zero Trust Landing Zone with FinOps & Green Cloud (2025)", 
    show=False, 
    filename="modern_cloud_architecture_2025", 
    direction="TB", 
    graph_attr=graph_attr
):

    internet = Internet("Internet/Users")
    on_prem = Server("On-Prem HQ\n(Hybrid)")

    with Cluster("🔐 DevSecOps Pipeline (Shift-Left Security)"):
        with Cluster("CI/CD"):
            repo = Repos("Git Repo")
            pipe = Pipelines("GitHub Actions")
            
        with Cluster("Security Scanners"):
            checkov = Python("Checkov\n(IaC Security)")
            trivy = Python("Trivy\n(Container)")
            opa = Python("OPA\n(Policy as Code)")
            
        repo >> pipe
        pipe >> Edge(label="Scan") >> [checkov, trivy, opa]

    with Cluster("☁️ Azure Cloud (Multi-Region)"):
        
        # Identity Layer
        with Cluster("🎫 Identity & Access (Zero Trust)"):
            entra = ActiveDirectory("Entra ID\n(Conditional Access)")
            managed_id = ManagedIdentities("Managed\nIdentities")
            
        # Governance Layer
        with Cluster("📊 Cloud Governance & FinOps"):
            azure_policy = Policy("Azure Policy\n(Guardrails)")
            cost_mgmt = CostManagement("Cost Mgmt\n+ Carbon Insights")
            
        # Hub Network
        with Cluster("🏢 HUB VNet (10.0.0.0/16) - Security Command Center"):
            hub_vnet = VirtualNetworks("Hub VNet")
            
            with Cluster("Security Stack"):
                azfw = Firewall("Azure Firewall\nPremium (IDPS)")
                waf = ApplicationGateway("App Gateway\n+ WAF v2")
                bastion = VM("Azure Bastion\nDeveloper SKU")
                
            with Cluster("Connectivity"):
                vpn = VirtualNetworkGateways("VPN Gateway\n(BGP + S2S)")
                expressroute = VirtualNetworkGateways("ExpressRoute\n(FastPath)")
                
            with Cluster("🤖 AI-Driven Security (SOAR)"):
                sentinel = Sentinel("Microsoft Sentinel\n(SIEM/SOAR)")
                defender = Defender("Defender for Cloud\n(CSPM/CWPP)")
                logs = LogAnalyticsWorkspaces("Log Analytics\n+ KQL Queries")
                ml_sec = MachineLearningServiceWorkspaces("ML Models\n(Anomaly Detection)")
                
                sentinel >> Edge(label="AI Threat Hunting") >> ml_sec
                defender >> logs >> sentinel

        # Spoke 1: Modern Apps (Containers)
        with Cluster("🚀 SPOKE 1: Container Platform (10.1.0.0/16)"):
            spoke1_vnet = VirtualNetworks("App Spoke")
            
            with Cluster("App Tier (K8s)"):
                aks = KubernetesServices("AKS\n(Calico Network Policy)")
                asg_app = ApplicationSecurityGroups("ASG: Web Tier")
                
            with Cluster("API Management"):
                apim = FrontDoors("Azure Front Door\n+ WAF Rules")
                
            udr1 = RouteTables("UDR\n(Force Tunnel)")

        # Spoke 2: Data & AI
        with Cluster("📊 SPOKE 2: Data Platform (10.2.0.0/16)"):
            spoke2_vnet = VirtualNetworks("Data Spoke")
            
            with Cluster("Data Tier (Zero Public Access)"):
                cosmos = CosmosDb("Cosmos DB\n(Global)")
                sql = SQLDatabases("Azure SQL\n(Always Encrypted)")
                storage = BlobStorage("Data Lake\nGen2")
                
            with Cluster("Private Connectivity"):
                pe_sql = PrivateEndpoint("Private Link\n(SQL)")
                pe_cosmos = PrivateEndpoint("Private Link\n(Cosmos)")
                pe_storage = PrivateEndpoint("Private Link\n(Storage)")
                
            with Cluster("AI/ML Workloads"):
                ml_workspace = MachineLearningServiceWorkspaces("Azure ML\n(MLOps)")
                
            udr2 = RouteTables("UDR\n(Inspection)")

        # Shared Services
        with Cluster("🔑 Shared Services"):
            kv = KeyVaults("Key Vault\n(HSM Backed)")
            monitoring = Monitor("Azure Monitor\n+ App Insights")
            
        # Traffic Flow - Internet to Apps
        internet >> Edge(color="red", style="bold", label="HTTPS") >> apim
        apim >> Edge(color="orange") >> waf >> azfw >> aks
        
        # On-Prem Connectivity
        on_prem >> Edge(color="blue", label="Site-to-Site VPN") >> vpn
        on_prem >> Edge(color="darkblue", label="Dedicated Line") >> expressroute
        [vpn, expressroute] >> azfw
        
        # Hub-Spoke Peering
        hub_vnet >> Edge(color="green", style="bold", label="VNet Peering") >> spoke1_vnet
        hub_vnet >> Edge(color="green", style="bold", label="VNet Peering") >> spoke2_vnet
        
        # Force Tunneling (All traffic through Firewall)
        udr1 >> Edge(color="red", label="0.0.0.0/0") >> azfw
        udr2 >> Edge(color="red", label="0.0.0.0/0") >> azfw
        
        # App to Data (Private Link)
        aks >> Edge(color="purple", style="dashed", label="Private") >> pe_sql >> sql
        aks >> Edge(color="purple", style="dashed") >> pe_cosmos >> cosmos
        aks >> Edge(color="purple", style="dashed") >> pe_storage >> storage
        
        # Identity Integration
        entra >> Edge(label="AuthN/AuthZ") >> [aks, apim]
        managed_id >> Edge(label="Password-less") >> [sql, cosmos, kv, storage]
        
        # Governance
        azure_policy >> Edge(label="Enforce", style="dotted") >> [spoke1_vnet, spoke2_vnet]
        cost_mgmt >> Edge(label="Monitor", style="dotted") >> [aks, cosmos, sql]
        
        # Security Monitoring (Everything to Sentinel)
        [azfw, waf, aks, sql, cosmos] >> Edge(color="orange", label="Logs") >> logs
        
        # DevOps Deployment
        pipe >> Edge(color="purple", style="dashed", label="Deploy") >> [aks, sql]
        
        # Secrets Management
        aks >> Edge(label="CSI Driver") >> kv
        
        # ML Integration
        ml_workspace >> Edge(label="Training Data") >> storage
        ml_workspace >> Edge(label="Deploy Models") >> aks

print("✅ Diagram generated: modern_cloud_architecture_2025.png")
