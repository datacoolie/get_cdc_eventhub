from faker import Faker
import random

fake = Faker()

def random_product():
    name = fake.unique.word().capitalize() + ' ' + random.choice(['Pro','Plus','X','Mini','Max'])
    return {
        'product_name': name,
        'category': random.choice(['Electronics','Furniture','Office','Accessories']),
        'description': fake.sentence(nb_words=6),
        'price': round(random.uniform(5,1500),2),
        'stock_quantity': random.randint(0,500),
        'supplier_name': fake.company(),
        'status': random.choice(['ACTIVE','DISCONTINUED'])
    }

def random_inventory_tx(product_id=None):
    tx_type = random.choice(['IN','OUT','ADJUSTMENT'])
    qty = random.randint(1,50)
    if tx_type == 'OUT':
        qty = random.randint(1,10)
    return {
        'product_id': product_id or random.randint(1,10),
        'transaction_type': tx_type,
        'quantity': qty,
        'reference_number': f"REF-{fake.unique.lexify(text='????')}-{random.randint(100,999)}",
        'notes': fake.sentence(nb_words=8),
        'performed_by': random.choice(['admin','warehouse','system'])
    }
