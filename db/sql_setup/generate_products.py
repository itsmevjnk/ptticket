#!/usr/bin/env python3

durations = [
    120, 120, # 1-2
    150, 150, 150, # 3-5
    180, 180, 180, # 6-8
    210, 210, 210, # 9-11
    240, 240, 240, # 12-14
    270 # 15
]

def make_definition(name: str, fromZone: int, toZone: int) -> dict[str, str | int]:
    return {
        'name': name,
        'fromZone': fromZone,
        'toZone': toZone, 
        '2hrDuration': durations[toZone - fromZone]
    }

products = []
products.append(make_definition('None', 0, 0))
products.append(make_definition('Zone 1+2', 1, 2))
products.append(make_definition('Zone 1+2+3', 1, 3))
products.append(make_definition('Zone 1/2 overlap', 0, 0)) # zones covered will be determined upon touch-off
products.append(make_definition('Zones 1-15', 1, 15))
for zone in range(2, 16): products.append(make_definition(f'Zone {zone}', zone, zone)) # single zone
for nZones in range(2, 15): # 2-14 regional zones
    for zone in range(2, 17 - nZones):
        products.append(make_definition(f'Zones {zone}-{zone + nZones - 1}', zone, zone + nZones - 1))

# export as JSON file
products_dict = {id: definition for id, definition in enumerate(products)}
import json
with open('products.json', 'w') as f:
    json.dump(products_dict, f, indent=4)

# export as PostgreSQL insertions
with open('products.sql', 'w') as f:
    f.write('PREPARE insert_product(int, varchar(24), int, int, int) AS INSERT INTO "static"."Products" VALUES ($1, $2, $3, $4, $5);\n') # PREPARE statement (for improved efficiency)
    for id, definition in enumerate(products): f.write(f'EXECUTE insert_product({id}, \'{definition["name"]}\', {definition["fromZone"]}, {definition["toZone"]}, {definition["2hrDuration"]});\n')

print(f'Generated {len(products)} product definitions')