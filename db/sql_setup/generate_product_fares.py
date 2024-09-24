z2_fare = 330
z1_2_fare = 530
z1_3_fare = 900
fare_cap = 1060
regional_fares = [280, 380, 420, 520, 600, 740, 900, fare_cap, fare_cap, fare_cap, fare_cap, fare_cap, fare_cap, fare_cap]

with open('product_fares.sql', 'w') as f:
    f.write('PREPARE insert_product_fare(int, int, int, int) AS INSERT INTO "static"."ProductFares" VALUES ($1, $2, $3, $4);\n')

    for type in range(7): # fareType
        div = (2 if type > 0 else 1) # divisor for fares
        f.write(f'EXECUTE insert_product_fare(1, {type}, 0, {z1_2_fare // div});\n') # Zone 1+2
        f.write(f'EXECUTE insert_product_fare(2, {type}, 0, {z1_3_fare // div});\n') # Zone 1+2+3
        f.write(f'EXECUTE insert_product_fare(4, {type}, 0, {fare_cap // div});\n') # Zones 1-15
        f.write(f'EXECUTE insert_product_fare(5, {type}, 0, {z2_fare // div});\n') # Zone 2 only
        for id in range(6, 19):
            f.write(f'EXECUTE insert_product_fare({id}, {type}, 0, {regional_fares[0] // div});\n') # Zone 3-15 only
        id = 19
        for zones in range(2, 15):
            for i in range(15 - zones):
                f.write(f'EXECUTE insert_product_fare({id}, {type}, 0, {regional_fares[zones - 1] // div});\n')
                id += 1

    # free travel within 2 consecutive zones on weekends for carer/DSP/seniors
    for type in [3, 4, 5]:
        f.write(f'EXECUTE insert_product_fare(1, {type}, 1, 0);\n') # Zone 1+2
        for id in range(5, 32): # 5-18 (1 zone) and 19-31 (2 zones)
            f.write(f'EXECUTE insert_product_fare({id}, {type}, 1, 0);\n')
    
    # free travel on special occasions is enforced by daily fare cap