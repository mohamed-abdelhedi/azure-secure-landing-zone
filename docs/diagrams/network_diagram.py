from diagrams import Diagram, Cluster, Edge
from diagrams.azure.network import VirtualNetworks, Firewall, Subnets, VirtualNetworkGateways
from diagrams.azure.compute import VM
from diagrams.azure.general import Backlog

graph_attr = {
    "fontsize": "16",
    "bgcolor": "white",
    "pad": "1.0",
    "nodesep": "1.0",
    "ranksep": "1.5"
}

with Diagram(
    "Hub-and-Spoke Network Architecture with IP Addressing",
    show=False,
    filename="network_addressing_diagram",
    direction="TB",
    graph_attr=graph_attr
):
    
    with Cluster("🏢 HUB VNet\n10.0.0.0/16\n(65,536 IPs)"):
        hub = VirtualNetworks("vnet-hub-dev-eastus-001")
        
        with Cluster("Subnets"):
            fw_subnet = Subnets("AzureFirewallSubnet\n10.0.0.0/26\n(64 IPs)")
            gw_subnet = Subnets("GatewaySubnet\n10.0.1.0/26\n(64 IPs)")
            bastion_subnet = Subnets("AzureBastionSubnet\n10.0.2.0/26\n(64 IPs)")
        
        with Cluster("Security Services"):
            firewall = Firewall("Azure Firewall\nPrivate IP: 10.0.0.4")
            bastion = VM("Bastion\n(Secure Access)")
        
        fw_subnet >> firewall
        bastion_subnet >> bastion
    
    with Cluster("🚀 APP SPOKE VNet\n10.1.0.0/16\n(65,536 IPs)"):
        app_spoke = VirtualNetworks("vnet-app-dev-eastus-001")
        
        with Cluster("Subnets"):
            aks_subnet = Subnets("snet-aks-dev\n10.1.0.0/22\n(1,024 IPs)\nFor Kubernetes pods")
            appgw_subnet = Subnets("snet-appgw-dev\n10.1.4.0/24\n(256 IPs)\nFor App Gateway")
        
        with Cluster("Routing"):
            app_route = Backlog("UDR (Route Table)\n0.0.0.0/0 → 10.0.0.4\n(Force all traffic to Firewall)")
    
    with Cluster("📊 DATA SPOKE VNet\n10.2.0.0/16\n(65,536 IPs)"):
        data_spoke = VirtualNetworks("vnet-data-dev-eastus-001")
        
        with Cluster("Subnets"):
            data_subnet = Subnets("snet-data-dev\n10.2.0.0/24\n(256 IPs)\nFor Databases")
            pe_subnet = Subnets("snet-privatelink-dev\n10.2.1.0/24\n(256 IPs)\nFor Private Endpoints")
        
        with Cluster("Routing"):
            data_route = Backlog("UDR (Route Table)\n0.0.0.0/0 → 10.0.0.4\n(Force all traffic to Firewall)")
    
    # Peering connections
    hub >> Edge(color="blue", style="bold", label="VNet Peering") >> app_spoke
    hub >> Edge(color="blue", style="bold", label="VNet Peering") >> data_spoke
    
    # Routing flow
    app_route >> Edge(color="red", label="All traffic\ninspected") >> firewall
    data_route >> Edge(color="red", label="All traffic\ninspected") >> firewall

print("✅ Network diagram generated: network_addressing_diagram.png")
