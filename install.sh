#!/bin/bash
# Script de Instalação MultiMine para Pterodactyl
# Versão: 1.0
# Autor: Claude 3.7 Sonnet
# Este script permite instalar diferentes tipos de servidores Minecraft de forma interativa

# Diretório do servidor
APP_DIR=/mnt/server

# Certifique-se de que o diretório do servidor existe
mkdir -p $APP_DIR
cd $APP_DIR

# Função para exibir o banner
show_banner() {
    echo "====================================================================="
    echo "     MultiMine - Instalador Avançado de Servidor Minecraft           "
    echo "====================================================================="
}

# Função para exibir tipos de servidores disponíveis
show_server_types() {
    echo "[1] Vanilla - Minecraft oficial sem modificações"
    echo "[2] Paper - Alto desempenho com suporte a plugins"
    echo "[3] Purpur - Fork do Paper com mais otimizações"
    echo "[4] Spigot - Servidor popular com suporte a plugins"
    echo "[5] Forge - Suporte a mods"
    echo "[6] Fabric - Alternativa leve ao Forge para mods"
    echo "[7] Sponge - Compatível com plugins e mods"
    echo "[8] Mohist - Híbrido Forge+Bukkit/Spigot com suporte a mods e plugins"
    echo "[9] Magma - Fork do Mohist com melhorias"
}

# Função para obter as versões disponíveis de cada tipo de servidor
get_versions() {
    SERVER_TYPE=$1
    case $SERVER_TYPE in
        1) # Vanilla
            echo "Obtendo versões do Vanilla Minecraft..."
            curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r '.versions[] | select(.type == "release") | .id' | head -n 20
            ;;
        2) # Paper
            echo "Obtendo versões do Paper..."
            curl -s https://api.papermc.io/v2/projects/paper | jq -r '.versions[]' | sort -V -r | head -n 20
            ;;
        3) # Purpur
            echo "Obtendo versões do Purpur..."
            curl -s https://api.purpurmc.org/v2/purpur | jq -r '.versions[]' | sort -V -r | head -n 20
            ;;
        4) # Spigot
            echo "Obtendo versões do Spigot..."
            curl -s https://hub.spigotmc.org/versions/ --list-only | grep -v LATEST | sort -V -r | head -n 20
            ;;
        5) # Forge
            echo "Versões do Forge disponíveis:"
            echo "1.20.4"
            echo "1.20.1"
            echo "1.19.4"
            echo "1.19.2"
            echo "1.18.2"
            echo "1.16.5"
            echo "1.12.2"
            echo "1.7.10"
            ;;
        6) # Fabric
            echo "Obtendo versões do Fabric..."
            curl -s https://meta.fabricmc.net/v2/versions/game | jq -r '.[] | select(.stable == true) | .version' | head -n 20
            ;;
        7) # Sponge
            echo "Versões do Sponge disponíveis:"
            echo "1.19.2"
            echo "1.18.2"
            echo "1.16.5"
            echo "1.12.2"
            echo "1.8.9"
            ;;
        8) # Mohist
            echo "Versões do Mohist disponíveis:"
            echo "1.20.1"
            echo "1.19.2"
            echo "1.18.2"
            echo "1.16.5"
            echo "1.12.2"
            ;;
        9) # Magma
            echo "Versões do Magma disponíveis:"
            echo "1.19.3"
            echo "1.18.2"
            echo "1.16.5"
            echo "1.12.2"
            ;;
    esac
}

# Função para obter recomendação de memória RAM
get_ram_recommendation() {
    SERVER_TYPE=$1
    VERSION=$2
    
    # Extrai a versão principal (por exemplo, 1.16.5 -> 1.16)
    MAJOR_VERSION=$(echo $VERSION | grep -oE '^1\.[0-9]+')
    
    echo "Recomendação de memória RAM:"
    
    # Base na versão principal
    if [[ "$MAJOR_VERSION" == "1.7" || "$MAJOR_VERSION" == "1.8" ]]; then
        BASE_RAM="1GB para poucos jogadores, 2-3GB para 10+ jogadores"
    elif [[ "$MAJOR_VERSION" == "1.12" ]]; then
        BASE_RAM="2GB para poucos jogadores, 3-4GB para 10+ jogadores"
    elif [[ "$MAJOR_VERSION" == "1.16" ]]; then
        BASE_RAM="3GB para poucos jogadores, 4-6GB para 10+ jogadores"
    elif [[ "$MAJOR_VERSION" == "1.18" || "$MAJOR_VERSION" == "1.19" ]]; then
        BASE_RAM="4GB para poucos jogadores, 6-8GB para 10+ jogadores"
    else # 1.20+
        BASE_RAM="4GB para poucos jogadores, 8GB+ para 10+ jogadores"
    fi
    
    # Ajuste baseado no tipo de servidor
    case $SERVER_TYPE in
        1) # Vanilla
            echo "Vanilla ($VERSION): $BASE_RAM"
            ;;
        2|3|4) # Paper, Purpur, Spigot
            echo "$( [[ $SERVER_TYPE -eq 2 ]] && echo 'Paper' || [[ $SERVER_TYPE -eq 3 ]] && echo 'Purpur' || echo 'Spigot') ($VERSION): $BASE_RAM (mais eficiente que Vanilla)"
            ;;
        5|8|9) # Forge, Mohist, Magma
            echo "$( [[ $SERVER_TYPE -eq 5 ]] && echo 'Forge' || [[ $SERVER_TYPE -eq 8 ]] && echo 'Mohist' || echo 'Magma') ($VERSION): Adicione 1-2GB ao básico para cada 50 mods"
            ;;
        6) # Fabric
            echo "Fabric ($VERSION): Adicione 0.5-1GB ao básico para cada 50 mods (mais eficiente que Forge)"
            ;;
        7) # Sponge
            echo "Sponge ($VERSION): $BASE_RAM + 1GB para plugins"
            ;;
    esac
}

# Função para recomendar versão Java
recommend_java() {
    VERSION=$1
    
    # Extrai o número da versão secundária (por exemplo, 1.16.5 -> 16)
    MINOR_VERSION=$(echo $VERSION | grep -oE '1\.([0-9]+)' | cut -d'.' -f2)
    
    if [[ $MINOR_VERSION -ge 18 ]]; then
        echo "Java 17 ou mais recente recomendado para Minecraft $VERSION"
    elif [[ $MINOR_VERSION -eq 17 ]]; then
        echo "Java 16 ou 17 recomendado para Minecraft $VERSION"
    elif [[ $MINOR_VERSION -ge 13 ]]; then
        echo "Java 11 recomendado para Minecraft $VERSION"
    else
        echo "Java 8 recomendado para Minecraft $VERSION"
    fi
}

# Função para baixar o servidor baseado no tipo e versão
download_server() {
    SERVER_TYPE=$1
    VERSION=$2
    
    # Cria um diretório de logs
    mkdir -p logs
    
    case $SERVER_TYPE in
        1) # Vanilla
            echo "Baixando Minecraft Vanilla versão $VERSION..."
            MANIFEST_URL=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r --arg VERSION "$VERSION" '.versions[] | select(.id==$VERSION) | .url')
            DOWNLOAD_URL=$(curl -s $MANIFEST_URL | jq -r '.downloads.server.url')
            curl -o server.jar $DOWNLOAD_URL
            echo "eula=true" > eula.txt
            SERVER_JARFILE="server.jar"
            ;;
        2) # Paper
            echo "Baixando Paper versão $VERSION..."
            LATEST_BUILD=$(curl -s https://api.papermc.io/v2/projects/paper/versions/$VERSION/builds | jq -r '.builds[-1].build')
            DOWNLOAD_URL="https://api.papermc.io/v2/projects/paper/versions/$VERSION/builds/$LATEST_BUILD/downloads/paper-$VERSION-$LATEST_BUILD.jar"
            curl -o paper.jar $DOWNLOAD_URL
            echo "eula=true" > eula.txt
            SERVER_JARFILE="paper.jar"
            
            # Cria diretório de plugins
            mkdir -p plugins
            ;;
        3) # Purpur
            echo "Baixando Purpur versão $VERSION..."
            LATEST_BUILD=$(curl -s https://api.purpurmc.org/v2/purpur/$VERSION | jq -r '.builds.latest')
            DOWNLOAD_URL="https://api.purpurmc.org/v2/purpur/$VERSION/$LATEST_BUILD/download"
            curl -o purpur.jar $DOWNLOAD_URL
            echo "eula=true" > eula.txt
            SERVER_JARFILE="purpur.jar"
            
            # Cria diretório de plugins
            mkdir -p plugins
            ;;
        4) # Spigot
            echo "Baixando e compilando Spigot versão $VERSION..."
            echo "Este processo pode levar alguns minutos..."
            curl -o BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar
            java -jar BuildTools.jar --rev $VERSION
            mv spigot-$VERSION.jar spigot.jar
            echo "eula=true" > eula.txt
            SERVER_JARFILE="spigot.jar"
            
            # Cria diretório de plugins
            mkdir -p plugins
            ;;
        5) # Forge
            echo "Instalando Forge versão $VERSION..."
            # Determina a versão do instalador Forge baseado na versão Minecraft
            case $VERSION in
                1.20.4)
                    FORGE_VERSION="1.20.4-49.0.19"
                    ;;
                1.20.1)
                    FORGE_VERSION="1.20.1-47.2.0"
                    ;;
                1.19.4)
                    FORGE_VERSION="1.19.4-45.2.0"
                    ;;
                1.19.2)
                    FORGE_VERSION="1.19.2-43.2.14"
                    ;;
                1.18.2)
                    FORGE_VERSION="1.18.2-40.2.10"
                    ;;
                1.16.5)
                    FORGE_VERSION="1.16.5-36.2.39"
                    ;;
                1.12.2)
                    FORGE_VERSION="1.12.2-14.23.5.2860"
                    ;;
                1.7.10)
                    FORGE_VERSION="1.7.10-10.13.4.1614"
                    ;;
            esac
            
            # Baixa o instalador
            echo "Baixando instalador Forge $FORGE_VERSION..."
            DOWNLOAD_URL="https://maven.minecraftforge.net/net/minecraftforge/forge/$FORGE_VERSION/forge-$FORGE_VERSION-installer.jar"
            curl -o forge-installer.jar $DOWNLOAD_URL
            
            # Instala o Forge
            echo "Executando instalador do Forge..."
            java -jar forge-installer.jar --installServer
            
            # Cria diretório de mods
            mkdir -p mods
            
            # Determina o nome do arquivo jar correto com base na versão
            if [[ "$VERSION" == "1.7.10" || "$VERSION" == "1.12.2" ]]; then
                SERVER_JARFILE="forge-$FORGE_VERSION-universal.jar"
            else
                SERVER_JARFILE="forge-$FORGE_VERSION-server.jar"
            fi
            
            echo "eula=true" > eula.txt
            ;;
        6) # Fabric
            echo "Instalando Fabric versão $VERSION..."
            # Baixa o instalador do Fabric
            curl -o fabric-installer.jar https://maven.fabricmc.net/net/fabricmc/fabric-installer/0.11.2/fabric-installer-0.11.2.jar
            
            # Instala o Fabric
            java -jar fabric-installer.jar server -mcversion $VERSION -downloadMinecraft
            
            # Cria diretório de mods
            mkdir -p mods
            
            SERVER_JARFILE="fabric-server-launch.jar"
            echo "eula=true" > eula.txt
            ;;
        7) # Sponge
            echo "Instalando Sponge versão $VERSION..."
            # Determina a URL de download com base na versão
            case $VERSION in
                1.19.2)
                    SPONGE_URL="https://repo.spongepowered.org/repository/maven-releases/org/spongepowered/spongevanilla/1.19.2-10.0.0-RC1428/spongevanilla-1.19.2-10.0.0-RC1428.jar"
                    ;;
                1.18.2)
                    SPONGE_URL="https://repo.spongepowered.org/repository/maven-releases/org/spongepowered/spongevanilla/1.18.2-10.0.0-RC1424/spongevanilla-1.18.2-10.0.0-RC1424.jar"
                    ;;
                1.16.5)
                    SPONGE_URL="https://repo.spongepowered.org/repository/maven-releases/org/spongepowered/spongevanilla/1.16.5-8.1.0-RC1119/spongevanilla-1.16.5-8.1.0-RC1119.jar"
                    ;;
                1.12.2)
                    SPONGE_URL="https://repo.spongepowered.org/repository/maven-releases/org/spongepowered/spongevanilla/1.12.2-7.4.0/spongevanilla-1.12.2-7.4.0.jar"
                    ;;
                1.8.9)
                    SPONGE_URL="https://repo.spongepowered.org/repository/maven-releases/org/spongepowered/spongevanilla/1.8.9-6.1.0-BETA-27/spongevanilla-1.8.9-6.1.0-BETA-27.jar"
                    ;;
            esac
            
            # Baixa o Sponge
            curl -o sponge.jar $SPONGE_URL
            
            SERVER_JARFILE="sponge.jar"
            echo "eula=true" > eula.txt
            
            # Cria diretório de mods e plugins
            mkdir -p mods plugins
            ;;
        8) # Mohist
            echo "Baixando Mohist versão $VERSION..."
            # Determina a URL de download com base na versão
            case $VERSION in
                1.20.1)
                    MOHIST_URL="https://mohistmc.com/api/v2/projects/mohist/1.20.1/builds/latest/download"
                    ;;
                1.19.2)
                    MOHIST_URL="https://mohistmc.com/api/v2/projects/mohist/1.19.2/builds/latest/download"
                    ;;
                1.18.2)
                    MOHIST_URL="https://mohistmc.com/api/v2/projects/mohist/1.18.2/builds/latest/download"
                    ;;
                1.16.5)
                    MOHIST_URL="https://mohistmc.com/api/v2/projects/mohist/1.16.5/builds/latest/download"
                    ;;
                1.12.2)
                    MOHIST_URL="https://mohistmc.com/api/v2/projects/mohist/1.12.2/builds/latest/download"
                    ;;
            esac
            
            # Baixa o Mohist
            curl -o mohist.jar $MOHIST_URL
            
            SERVER_JARFILE="mohist.jar"
            echo "eula=true" > eula.txt
            
            # Cria diretório de mods e plugins
            mkdir -p mods plugins
            ;;
        9) # Magma
            echo "Baixando Magma versão $VERSION..."
            # Determina a URL de download com base na versão
            case $VERSION in
                1.19.3)
                    MAGMA_URL="https://api.magmafoundation.org/api/v2/1.19.3/latest/download"
                    ;;
                1.18.2)
                    MAGMA_URL="https://api.magmafoundation.org/api/v2/1.18.2/latest/download"
                    ;;
                1.16.5)
                    MAGMA_URL="https://api.magmafoundation.org/api/v2/1.16.5/latest/download"
                    ;;
                1.12.2)
                    MAGMA_URL="https://api.magmafoundation.org/api/v2/1.12.2/latest/download"
                    ;;
            esac
            
            # Baixa o Magma
            curl -o magma.jar $MAGMA_URL
            
            SERVER_JARFILE="magma.jar"
            echo "eula=true" > eula.txt
            
            # Cria diretório de mods e plugins
            mkdir -p mods plugins
            ;;
    esac
    
    echo "Servidor $SERVER_JARFILE instalado com sucesso!"
    return 0
}

# Função para criar script de inicialização com flags otimizadas
create_start_script() {
    SERVER_TYPE=$1
    VERSION=$2
    SERVER_JARFILE=$3
    
    # Extrai a versão principal para recomendações de flags Java
    MINOR_VERSION=$(echo $VERSION | grep -oE '1\.([0-9]+)' | cut -d'.' -f2)
    
    echo "Criando script de inicialização..."
    
    # Determina flags Java apropriadas com base na versão
    # Flags básicas para todas as versões
    JAVA_FLAGS="-XX:+UseG1GC -XX:+DisableExplicitGC -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+ParallelRefProcEnabled -XX:+OptimizeStringConcat"
    
    # Adiciona flags específicas para versões mais recentes
    if [[ $MINOR_VERSION -ge 17 ]]; then
        JAVA_FLAGS="$JAVA_FLAGS -XX:G1HeapRegionSize=32M -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1ReservePercent=20"
    elif [[ $MINOR_VERSION -ge 13 ]]; then
        JAVA_FLAGS="$JAVA_FLAGS -XX:G1HeapRegionSize=16M -XX:G1NewSizePercent=25 -XX:G1ReservePercent=15"
    else
        JAVA_FLAGS="$JAVA_FLAGS -XX:SurvivorRatio=12 -XX:+UseConcMarkSweepGC"
    fi
    
    # Cria o script de inicialização
    cat > start.sh << EOL
#!/bin/bash
# Script de inicialização gerado automaticamente para $SERVER_JARFILE

# Configurações de memória - ajuste conforme necessário
# Recomendação mínima para Minecraft $VERSION
MIN_RAM="1G"
MAX_RAM="4G"

# Flags de otimização Java
JAVA_FLAGS="$JAVA_FLAGS"

# Inicia o servidor
java -Xms\$MIN_RAM -Xmx\$MAX_RAM \$JAVA_FLAGS -jar $SERVER_JARFILE nogui
EOL

    # Torna o script executável
    chmod +x start.sh
    echo "Script de inicialização criado: start.sh"
}

# Função para exibir o resumo da instalação
show_installation_summary() {
    SERVER_TYPE=$1
    VERSION=$2
    SERVER_JARFILE=$3
    
    echo "====================================================================="
    echo "              RESUMO DA INSTALAÇÃO                                   "
    echo "====================================================================="
    echo "Tipo de servidor: $(case $SERVER_TYPE in
                              1) echo "Vanilla";;
                              2) echo "Paper";;
                              3) echo "Purpur";;
                              4) echo "Spigot";;
                              5) echo "Forge";;
                              6) echo "Fabric";;
                              7) echo "Sponge";;
                              8) echo "Mohist";;
                              9) echo "Magma";;
                            esac)"
    echo "Versão: $VERSION"
    echo "Arquivo JAR: $SERVER_JARFILE"
    echo ""
    recommend_java $VERSION
    echo ""
    get_ram_recommendation $SERVER_TYPE $VERSION
    echo ""
    echo "Para iniciar o servidor, execute: ./start.sh"
    echo "====================================================================="
}

# Função para criar server.properties com configurações recomendadas
create_server_properties() {
    echo "Criando arquivo server.properties com configurações recomendadas..."
    
    cat > server.properties << EOL
# Arquivo server.properties gerado por MultiMine
# $(date)

# Configurações básicas
server-port=25565
motd=Servidor Minecraft gerenciado por MultiMine
max-players=20
gamemode=survival
difficulty=normal
pvp=true
enable-command-block=false
allow-nether=true
force-gamemode=false
hardcore=false
white-list=false

# Performance
view-distance=10
entity-broadcast-range-percentage=100
simulation-distance=8
max-tick-time=60000
network-compression-threshold=256

# Mundo
level-name=world
level-seed=
level-type=default
generator-settings=
generate-structures=true
max-world-size=29999984

# Jogabilidade
spawn-protection=16
max-build-height=256
spawn-npcs=true
spawn-animals=true
spawn-monsters=true
spawn-protection=16

# Recursos avançados
enable-jmx-monitoring=false
enable-query=false
enable-rcon=false
query.port=25565
rcon.port=25575
rcon.password=
enable-status=true
broadcast-rcon-to-ops=true
broadcast-console-to-ops=true
function-permission-level=2
op-permission-level=4
prevent-proxy-connections=false
use-native-transport=true
enable-status=true
allow-flight=false
EOL

    echo "Arquivo server.properties criado com sucesso!"
}

# Função principal
main() {
    show_banner
    
    echo "Bem-vindo ao instalador MultiMine para Pterodactyl!"
    echo "Este script instalará um servidor Minecraft no diretório atual."
    echo ""
    
    # Exibe os tipos de servidor disponíveis
    echo "Selecione o tipo de servidor:"
    show_server_types
    echo ""
    
    # Solicita a seleção do tipo de servidor
    read -p "Digite o número correspondente ao tipo de servidor desejado (1-9): " SERVER_TYPE
    
    # Valida a entrada
    if ! [[ "$SERVER_TYPE" =~ ^[1-9]$ ]]; then
        echo "Opção inválida. Por favor, digite um número de 1 a 9."
        exit 1
    fi
    
    echo ""
    echo "Obtendo versões disponíveis..."
    get_versions $SERVER_TYPE
    echo ""
    
    # Solicita a versão desejada
    read -p "Digite a versão desejada (ex: 1.20.4): " VERSION
    
    echo ""
    echo "Iniciando instalação..."
    
    # Baixa o servidor
    download_server $SERVER_TYPE $VERSION
    
    # Armazena o nome do arquivo JAR para uso posterior
    SERVER_JARFILE=${SERVER_JARFILE:-"server.jar"}
    
    # Cria o arquivo server.properties
    create_server_properties
    
    # Cria o script de inicialização
    create_start_script $SERVER_TYPE $VERSION $SERVER_JARFILE
    
    # Exibe o resumo da instalação
    show_installation_summary $SERVER_TYPE $VERSION $SERVER_JARFILE
}

# Executa a função principal
main

exit 0