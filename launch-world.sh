#!/bin/bash

# Show available worlds
echo "Available worlds:"
echo "-----------------"
ls -1 worlds/
echo -e "\nEnter world name to launch (or q to quit): " 
read worldname

if [ "$worldname" = "q" ]; then
    exit 0
fi

if [ -d "worlds/$worldname" ]; then
    echo -e "\nGame Settings:"
    read -p "Enable Creative Mode? (y/n): " creative
    read -p "Enable Damage? (y/n): " damage

    # Create temporary config file with game settings
    TEMP_CONFIG=$(mktemp)
    echo "creative_mode = ${creative,,}" >> "$TEMP_CONFIG"
    echo "enable_damage = ${damage,,}" >> "$TEMP_CONFIG"

    echo -e "\nLaunching $worldname..."
    GAMEID=$(grep "gameid" "worlds/$worldname/world.mt" | cut -d "=" -f2 | tr -d " ")
    
    # Launch with config file
    ./bin/Sandboxy --go --world "$(pwd)/worlds/$worldname" --gameid "$GAMEID" --config "$TEMP_CONFIG"
    
    # Clean up temp config
    rm -f "$TEMP_CONFIG"
else
    echo "World not found!"
fi
