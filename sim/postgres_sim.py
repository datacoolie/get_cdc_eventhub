import argparse
import time
import random
import psycopg2
from psycopg2.extras import RealDictCursor
from common import random_product, random_inventory_tx


def connect(args):
    return psycopg2.connect(host=args.host, port=args.port, user=args.user, password=args.password, dbname=args.db)


def run_sim(args):
    conn = connect(args)
    conn.autocommit = False
    cur = conn.cursor(cursor_factory=RealDictCursor)
    print('Connected to Postgres at {}:{}'.format(args.host, args.port))
    i = 0
    try:
        while True:
            # perform a random operation
            op = random.choices(['insert_product','update_product','delete_product','insert_tx','delete_tx'], [0.3,0.25,0.05,0.2,0.2])[0]
            if op == 'insert_product':
                batch_size = random.randint(1, 3)
                data = []
                for _ in range(batch_size):
                    p = random_product()
                    data.append((p['product_name'], p['category'], p['description'], p['price'], p['stock_quantity'], p['supplier_name'], p['status']))
                cur.executemany(
                    """INSERT INTO datauser.products (product_name, category, description, price, stock_quantity, supplier_name, status) VALUES (%s,%s,%s,%s,%s,%s,%s)""",
                    data
                )
                conn.commit()
                print(f"Inserted {batch_size} products")
            elif op == 'update_product':
                batch_size = random.randint(1, 3)
                for _ in range(batch_size):
                    cur.execute("SELECT product_id FROM datauser.products ORDER BY random() LIMIT 1")
                    row = cur.fetchone()
                    if row:
                        pid = row['product_id']
                        cur.execute("UPDATE datauser.products SET price = price * (1 + (%s - 0.5)/10), stock_quantity = GREATEST(0, stock_quantity + %s) WHERE product_id = %s",
                                    (random.random(), random.randint(-5,5), pid))
                        conn.commit()
                        print(f"Updated product id={pid}")
                    else:
                        print('No product to update')
            elif op == 'delete_product':
                batch_size = random.randint(1, 2)
                ids_to_delete = []
                for _ in range(batch_size):
                    cur.execute("SELECT product_id FROM datauser.products ORDER BY random() LIMIT 1")
                    row = cur.fetchone()
                    if row and random.random()<0.5:
                        pid = row['product_id']
                        # Check if product has inventory transactions
                        cur.execute("SELECT COUNT(*) FROM datauser.inventory_transactions WHERE product_id = %s", (pid,))
                        tx_count = cur.fetchone()[0]
                        if tx_count == 0:
                            ids_to_delete.append(pid)
                if ids_to_delete:
                    placeholders = ', '.join(['%s'] * len(ids_to_delete))
                    cur.execute(f"DELETE FROM datauser.products WHERE product_id IN ({placeholders})", ids_to_delete)
                    conn.commit()
                    print(f"Deleted {len(ids_to_delete)} products")
                else:
                    print('No products to delete')
            elif op == 'delete_tx':
                batch_size = random.randint(1, 2)
                ids_to_delete = []
                for _ in range(batch_size):
                    cur.execute("SELECT transaction_id FROM datauser.inventory_transactions ORDER BY random() LIMIT 1")
                    row = cur.fetchone()
                    if row and random.random() < 0.6:
                        tid = row['transaction_id']
                        ids_to_delete.append(tid)
                if ids_to_delete:
                    placeholders = ', '.join(['%s'] * len(ids_to_delete))
                    cur.execute(f"DELETE FROM datauser.inventory_transactions WHERE transaction_id IN ({placeholders})", ids_to_delete)
                    conn.commit()
                    print(f"Deleted {len(ids_to_delete)} tx")
                else:
                    print('No tx to delete')
            elif op == 'insert_tx':
                batch_size = random.randint(1, 3)
                data = []
                for _ in range(batch_size):
                    cur.execute("SELECT product_id FROM datauser.products ORDER BY random() LIMIT 1")
                    row = cur.fetchone()
                    pid = row['product_id'] if row else None
                    tx = random_inventory_tx(product_id=pid)
                    data.append((tx['product_id'], tx['transaction_type'], tx['quantity'], tx['reference_number'], tx['notes'], tx['performed_by']))
                cur.executemany(
                    """INSERT INTO datauser.inventory_transactions (product_id, transaction_type, quantity, reference_number, notes, performed_by) VALUES (%s,%s,%s,%s,%s,%s)""",
                    data
                )
                conn.commit()
                print(f"Inserted {batch_size} tx")

            i += 1
            if args.iterations and i >= args.iterations:
                break
            time.sleep(1.0 / max(0.1, args.rate))
    except KeyboardInterrupt:
        print('Interrupted by user')
    finally:
        cur.close()
        conn.close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--host', default='localhost')
    parser.add_argument('--port', type=int, default=5432)
    parser.add_argument('--user', default='datauser')
    parser.add_argument('--password', default='DataPassword123')
    parser.add_argument('--db', default='cdcdb')
    parser.add_argument('--rate', type=float, default=1.0, help='ops per second')
    parser.add_argument('--iterations', type=int, default=0, help='0 means infinite')
    args = parser.parse_args()
    if args.iterations == 0:
        args.iterations = None
    run_sim(args)
