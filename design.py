from diagrams import Diagram, Cluster, Edge
# Adjusted based on your dir(network) output
from diagrams.azure.network import Firewall, VirtualNetworks, VirtualNetworkGateways, RouteTables, PrivateEndpoint, Subnets
from diagrams.azure.compute import VM, VMScaleSets
from diagrams.azure.database import SQLDatabases
from diagrams.azure.security import Sentinel, KeyVaults, Defender
from diagrams.azure.managementgovernance import LogAnalyticsWorkspaces
from diagrams.azure.devops import Pipelines, Repos
from diagrams.azure.general import ManagementGroups
from diagrams.onprem.network import Internet
from diagrams.onprem.compute import Server

graph_attr = {
    "fontsize": "20",
    "bgcolor": "white",
    "splines": "ortho",
    "pad": "0.5"
}

with Diagram("Secure Landing Zone 2.0", show=False, filename="secure_landing_zone_lld", direction="TB", graph_attr=graph_attr):

    internet = Internet("Internet")
    on_prem = Server("On-Prem HQ")

    with Cluster("DevSecOps Pipeline"):
        pipe = Pipelines("CI/CD (Checkov)")
        pipe << Repos("Terraform Code")

    with Cluster("Azure Cloud"):
        # Management
        la = LogAnalyticsWorkspaces("Logs")
        sentinel = Sentinel("Sentinel SIEM")
        
        with Cluster("HUB VNet (10.0.0.0/20)"):
            hub_vnet = VirtualNetworks("Hub")
            azfw = Firewall("Azure Firewall\nPremium")
            vpn = VirtualNetworkGateways("VPN Gateway")
            # Using a VM labeled Bastion since it's missing in your library version
            bastion = VM("Bastion Host") 

        with Cluster("PROD Spoke VNet (10.1.0.0/20)"):
            prod_vnet = VirtualNetworks("Prod")
            udr = RouteTables("UDR (Force Tunnel)")
            
            with Cluster("App Tier"):
                app_vm = VMScaleSets("App Services")
            
            with Cluster("Data Tier"):
                db = SQLDatabases("Azure SQL")
                # Using the singular PrivateEndpoint from your dir() list
                pe = PrivateEndpoint("Private Link")
                app_vm >> pe >> db

        # Connections
        internet >> azfw
        on_prem >> vpn >> azfw
        hub_vnet - Edge(color="blue", style="bold") - prod_vnet
        udr >> Edge(color="red") >> azfw
        app_vm >> udr

    pipe >> Edge(color="purple", style="dashed") >> hub_vnet