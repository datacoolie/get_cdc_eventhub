import argparse
import time
import random
import oracledb
from common import random_product


def connect(args):
    dsn = f"{args.host}:{args.port}/{args.service}"
    # use thin mode if available (no Instant Client required)
    oracledb.init_oracle_client() if False else None
    return oracledb.connect(user=args.user, password=args.password, dsn=dsn)


def run_sim(args):
    conn = connect(args)
    cur = conn.cursor()
    print('Connected to Oracle at {}:{}'.format(args.host, args.port))
    i = 0
    try:
        while True:
            op = random.choices(['insert_customer','update_customer','delete_customer','insert_order','delete_order'], [0.3,0.25,0.05,0.2,0.2])[0]
            if op == 'insert_customer':
                batch_size = random.randint(1, 3)
                data = []
                for _ in range(batch_size):
                    first = random.choice(['Alice','Bob','Carol','Dave','Eve','Frank'])
                    last = random.choice(['Adams','Brown','Clark','Davis','Evans','Ford'])
                    email = f"{first.lower()}.{last.lower()}.{random.randint(1,999)}@example.com"
                    phone = f"+1-555-{random.randint(1000,9999)}"
                    data.append((first, last, email, phone, '100 Elm St', 'SomeCity', 'USA', 'ACTIVE', 1000.00))
                cur.executemany("INSERT INTO datauser.CUSTOMERS (customer_id, first_name, last_name, email, phone, address, city, country, status, credit_limit) VALUES (datauser.customers_seq.NEXTVAL, :1,:2,:3,:4,:5,:6,:7,:8,:9)", data)
                conn.commit()
                print(f"Inserted {batch_size} customers")
            elif op == 'update_customer':
                batch_size = random.randint(1, 3)
                for _ in range(batch_size):
                    cur.execute("SELECT customer_id FROM datauser.CUSTOMERS ORDER BY dbms_random.value FETCH FIRST 1 ROWS ONLY")
                    row = cur.fetchone()
                    if row:
                        cid = row[0]
                        cur.execute("UPDATE datauser.CUSTOMERS SET credit_limit = credit_limit + :1 WHERE customer_id = :2", (random.randint(0,500), cid))
                        conn.commit()
                        print(f"Updated customer id={cid}")
                    else:
                        print('No customer to update')
            elif op == 'delete_customer':
                batch_size = random.randint(1, 2)
                ids_to_delete = []
                for _ in range(batch_size):
                    cur.execute("SELECT customer_id FROM datauser.CUSTOMERS ORDER BY dbms_random.value FETCH FIRST 1 ROWS ONLY")
                    row = cur.fetchone()
                    if row and random.random() < 0.4:
                        cid = row[0]
                        # Check if customer has orders
                        cur.execute("SELECT COUNT(*) FROM datauser.ORDERS WHERE customer_id = :1", (cid,))
                        order_count = cur.fetchone()[0]
                        if order_count == 0:
                            ids_to_delete.append(cid)
                if ids_to_delete:
                    placeholders = ', '.join([f':{i+1}' for i in range(len(ids_to_delete))])
                    cur.execute(f"DELETE FROM datauser.CUSTOMERS WHERE customer_id IN ({placeholders})", ids_to_delete)
                    conn.commit()
                    print(f"Deleted {len(ids_to_delete)} customers")
                else:
                    print('No customers to delete')
            elif op == 'delete_order':
                batch_size = random.randint(1, 2)
                ids_to_delete = []
                for _ in range(batch_size):
                    cur.execute("SELECT order_id FROM datauser.ORDERS ORDER BY dbms_random.value FETCH FIRST 1 ROWS ONLY")
                    row = cur.fetchone()
                    if row and random.random() < 0.6:
                        oid = row[0]
                        ids_to_delete.append(oid)
                if ids_to_delete:
                    placeholders = ', '.join([f':{i+1}' for i in range(len(ids_to_delete))])
                    cur.execute(f"DELETE FROM datauser.ORDERS WHERE order_id IN ({placeholders})", ids_to_delete)
                    conn.commit()
                    print(f"Deleted {len(ids_to_delete)} orders")
                else:
                    print('No orders to delete')
            elif op == 'insert_order':
                batch_size = random.randint(1, 3)
                data = []
                for _ in range(batch_size):
                    # pick a customer
                    cur.execute("SELECT customer_id FROM datauser.CUSTOMERS ORDER BY dbms_random.value FETCH FIRST 1 ROWS ONLY")
                    row = cur.fetchone()
                    cid = row[0] if row else 1
                    order_num = f"ORD-{2025}-{random.randint(100,999)}"
                    total = round(random.uniform(20,2000),2)
                    data.append((cid, order_num, total, round(total*0.08,2), 'USD', random.choice(['CREDIT_CARD','PAYPAL','WIRE']), random.choice(['PENDING','PROCESSING','COMPLETED']), '123 Main St'))
                cur.executemany("INSERT INTO datauser.ORDERS (order_id, customer_id, order_number, total_amount, tax_amount, currency, payment_method, order_status, shipping_address) VALUES (datauser.orders_seq.NEXTVAL, :1, :2, :3, :4, :5, :6, :7, :8)", data)
                conn.commit()
                print(f"Inserted {batch_size} orders")

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
    parser.add_argument('--port', type=int, default=1521)
    parser.add_argument('--service', default='XEPDB1')
    parser.add_argument('--user', default='datauser')
    parser.add_argument('--password', default='DataPassword123')
    parser.add_argument('--rate', type=float, default=1.0, help='ops per second')
    parser.add_argument('--iterations', type=int, default=0, help='0 means infinite')
    args = parser.parse_args()
    if args.iterations == 0:
        args.iterations = None
    run_sim(args)
