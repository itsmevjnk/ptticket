#!/usr/bin/env python3

def make_definition(name: str, zones: list[int]) -> dict[str, str | int]:
    return {
        'name': name,
        'coveredZones': sum([(1 << (zone - 1)) for zone in zones])
    }

products = []
products.append(make_definition('None', []))
products.append(make_definition('Zone 1+2', [1, 2]))
products.append(make_definition('Zone 1+2+3', [1, 2, 3]))
products.append(make_definition('Zone 1/2 overlap', [])) # zones covered will be determined upon touch-off
products.append(make_definition('Zones 1-15', range(1, 16)))
for zone in range(2, 16): products.append(make_definition(f'Zone {zone}', [zone])) # single zone
for nZones in range(2, 15): # 2-14 regional zones
    for zone in range(2, 17 - nZones):
        products.append(make_definition(f'Zones {zone}-{zone + nZones - 1}', range(zone, zone + nZones)))

# export as JSON file
products_dict = {id: definition for id, definition in enumerate(products)}
import json
with open('products.json', 'w') as f:
    json.dump(products_dict, f, indent=4)

# export as PostgreSQL insertions
with open('products.sql', 'w') as f:
    f.write('PREPARE insert_product(int, varchar(24), int) AS INSERT INTO "static"."Products" VALUES ($1, $2, $3);\n') # PREPARE statement (for improved efficiency)
    for id, definition in enumerate(products): f.write(f'EXECUTE insert_product({id}, \'{definition["name"]}\', {definition["coveredZones"]});\n')

print(f'Generated {len(products)} product definitions')