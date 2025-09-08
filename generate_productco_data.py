import mysql.connector
from faker import Faker
import random
from datetime import datetime, timedelta

# Initialize Faker
fake = Faker()
fake.seed_instance(42)  # For reproducible data

# MySQL connection configuration - UPDATE YOUR PASSWORD!
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'kaushikyeddanapudi_75', 
    'database': 'productco_analytics',
    'charset': 'utf8mb4'
}

def connect_to_mysql():
    """Establish MySQL connection"""
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        print("✅ Connected to MySQL successfully!")
        return connection
    except mysql.connector.Error as e:
        print(f"❌ Error connecting to MySQL: {e}")
        return None

def generate_suppliers(connection, num_suppliers=100):
    print(f"🔄 Generating {num_suppliers} suppliers...")
    cursor = connection.cursor()
    
    suppliers_data = []
    for i in range(num_suppliers):
        suppliers_data.append((
            fake.company(),
            fake.country(),
            fake.company_email(),
            fake.phone_number(),
            round(random.uniform(3.0, 5.0), 2)
        ))
    
    cursor.executemany("""
        INSERT INTO dim_supplier (supplier_name, supplier_country, supplier_email, supplier_phone, rating)
        VALUES (%s, %s, %s, %s, %s)
    """, suppliers_data)
    
    connection.commit()
    cursor.close()
    print(f"✅ Generated {num_suppliers} suppliers!")

def generate_date_dimension(connection):
    print("🔄 Generating date dimension...")
    cursor = connection.cursor()
    
    start_date = datetime(2020, 1, 1)
    end_date = datetime(2024, 12, 31)
    
    dates_data = []
    current_date = start_date
    
    while current_date <= end_date:
        day_of_week = current_date.weekday() + 1  # 1=Monday, 7=Sunday
        day_name = current_date.strftime('%A')
        is_weekend = day_of_week in [6, 7]  # Saturday, Sunday
        is_holiday = random.random() < 0.03  # ~3% chance of holiday
        week_of_year = current_date.isocalendar().week  # Fixed here
        
        dates_data.append((
            current_date.date(),
            day_of_week,
            day_name,
            current_date.day,
            current_date.timetuple().tm_yday,
            week_of_year,
            current_date.month,
            current_date.strftime('%B'),
            (current_date.month - 1) // 3 + 1,
            current_date.year,
            is_weekend,
            is_holiday,
            current_date.year if current_date.month >= 4 else current_date.year - 1,
            ((current_date.month - 4) % 12) // 3 + 1 if current_date.month >= 4 else ((current_date.month + 8) % 12) // 3 + 1
        ))
        
        current_date += timedelta(days=1)
    
    cursor.executemany("""
        INSERT INTO dim_date (full_date, day_of_week, day_name, day_of_month, day_of_year, 
                             week_of_year, month, month_name, quarter, year, is_weekend, 
                             is_holiday, fiscal_year, fiscal_quarter)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """, dates_data)
    
    connection.commit()
    cursor.close()
    print(f"✅ Generated {len(dates_data)} date records!")

def generate_products(connection, num_products=1000):
    print(f"🔄 Generating {num_products} products...")
    cursor = connection.cursor()
    
    cursor.execute("SELECT supplier_id FROM dim_supplier")
    supplier_ids = [row[0] for row in cursor.fetchall()]
    
    categories = ['Electronics', 'Software', 'Hardware', 'Accessories', 'Services', 
                 'Mobile Devices', 'Cloud Solutions', 'Security', 'Analytics', 'Gaming']
    brands = ['TechCorp', 'InnovateSoft', 'GlobalTech', 'NextGen', 'ProSolutions',
             'DigitalFirst', 'SmartTech', 'FutureSystems', 'PowerTech', 'EliteProducts']
    
    products_data = []
    for i in range(num_products):
        category = random.choice(categories)
        subcategory = f"{category} {random.choice(['Basic', 'Pro', 'Enterprise', 'Premium'])}"
        
        products_data.append((
            f"{fake.catch_phrase()} {random.choice(['Device', 'Software', 'Solution', 'System'])}",
            category,
            subcategory,
            random.choice(brands),
            random.choice(supplier_ids),
            round(random.uniform(10.0, 500.0), 2),
            fake.date_between(start_date='-5y', end_date='now'),
            random.choice([True, True, True, False])  # 75% active
        ))
        
    cursor.executemany("""
        INSERT INTO dim_product (product_name, product_category, product_subcategory, brand, 
                                supplier_id, unit_cost, launch_date, is_active)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """, products_data)
    
    connection.commit()
    cursor.close()
    print(f"✅ Generated {num_products} products!")

def generate_customers(connection, num_customers=50000):
    print(f"🔄 Generating {num_customers:,} customers...")
    cursor = connection.cursor()
    
    industries = ['Technology', 'Healthcare', 'Finance', 'Retail', 'Manufacturing',
                 'Education', 'Media', 'Real Estate', 'Consulting', 'Non-Profit']
    
    countries = ['USA', 'Canada', 'UK', 'Germany', 'France', 'Australia',
                'Japan', 'India', 'Brazil', 'Netherlands', 'Singapore', 'Sweden']
    
    regions = ['North America', 'Europe', 'Asia Pacific', 'Latin America', 'Middle East']
    
    batch_size = 5000
    customers_data = []
    
    for i in range(num_customers):
        customer_type = random.choice(['B2B', 'B2C'])
        customers_data.append((
            fake.company() if customer_type == 'B2B' else fake.name(),
            customer_type,
            random.choice(industries) if customer_type == 'B2B' else None,
            random.choice(['Small', 'Medium', 'Large', 'Enterprise']) if customer_type == 'B2B' else 'Small',
            random.choice(countries),
            random.choice(regions),
            fake.city(),
            fake.date_between(start_date='-3y', end_date='now'),
            random.choice(['Bronze', 'Silver', 'Gold', 'Platinum'])
        ))
        
        if len(customers_data) >= batch_size:
            cursor.executemany("""
                INSERT INTO dim_customer (customer_name, customer_type, industry, company_size,
                                        country, region, city, acquisition_date, customer_tier)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, customers_data)
            connection.commit()
            print(f"   Inserted {i+1:,} customers...")
            customers_data = []
            
    if customers_data:
        cursor.executemany("""
            INSERT INTO dim_customer (customer_name, customer_type, industry, company_size,
                                    country, region, city, acquisition_date, customer_tier)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, customers_data)
        connection.commit()
        
    cursor.close()
    print(f"✅ Generated {num_customers:,} customers!")

def generate_stores(connection, num_stores=200):
    print(f"🔄 Generating {num_stores} stores...")
    cursor = connection.cursor()
    
    store_types = ['Online', 'Retail', 'Partner', 'Direct']
    regions = ['North America', 'Europe', 'Asia Pacific', 'Latin America', 'Middle East']
    countries = ['USA', 'Canada', 'UK', 'Germany', 'France', 'Australia',
                'Japan', 'India', 'Brazil', 'Netherlands', 'Singapore', 'Sweden']
    
    stores_data = []
    for i in range(num_stores):
        stores_data.append((
            f"{fake.city()} {random.choice(['Store', 'Center', 'Hub', 'Outlet'])}",
            random.choice(store_types),
            random.choice(regions),
            random.choice(countries),
            fake.city(),
            fake.name(),
            fake.date_between(start_date='-10y', end_date='-1y'),
            random.choice(['Small', 'Medium', 'Large'])
        ))
        
    cursor.executemany("""
        INSERT INTO dim_store (store_name, store_type, region, country, city, 
                              manager_name, opening_date, store_size)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """, stores_data)
    
    connection.commit()
    cursor.close()
    print(f"✅ Generated {num_stores} stores!")

def generate_sales_reps(connection, num_reps=500):
    print(f"🔄 Generating {num_reps} sales representatives...")
    cursor = connection.cursor()
    
    territories = ['North', 'South', 'East', 'West', 'Central', 'International']
    performance_tiers = ['Trainee', 'Junior', 'Senior', 'Expert', 'Master']
    
    reps_data = []
    for i in range(num_reps):
        reps_data.append((
            fake.name(),
            fake.company_email(),
            fake.date_between(start_date='-5y', end_date='-1m'),
            random.choice(territories),
            random.randint(1, max(1, i//10)) if i > 0 else None,  # Some reps report to others
            round(random.uniform(0.02, 0.15), 2),
            random.choice(performance_tiers),
            random.choice([True, True, True, False])  # 75% active
        ))
        
    cursor.executemany("""
        INSERT INTO dim_sales_rep (rep_name, rep_email, hire_date, territory, manager_id,
                                  commission_rate, performance_tier, is_active)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """, reps_data)
    
    connection.commit()
    cursor.close()
    print(f"✅ Generated {num_reps} sales representatives!")

def generate_sales_facts(connection, num_sales=1000000):
    print(f"🔄 Generating {num_sales:,} sales transactions...")
    cursor = connection.cursor()
    
    cursor.execute("SELECT product_id, unit_cost FROM dim_product WHERE is_active = TRUE")
    products = cursor.fetchall()
    
    cursor.execute("SELECT customer_id FROM dim_customer")
    customer_ids = [row[0] for row in cursor.fetchall()]
    
    cursor.execute("SELECT store_id FROM dim_store")
    store_ids = [row[0] for row in cursor.fetchall()]
    
    cursor.execute("SELECT date_id FROM dim_date")
    date_ids = [row[0] for row in cursor.fetchall()]
    
    cursor.execute("SELECT sales_rep_id FROM dim_sales_rep WHERE is_active = TRUE")
    rep_ids = [row[0] for row in cursor.fetchall()]
    
    batch_size = 10000
    sales_data = []
    
    for i in range(num_sales):
        product_id, unit_cost = random.choice(products)
        customer_id = random.choice(customer_ids)
        store_id = random.choice(store_ids)
        date_id = random.choice(date_ids)
        sales_rep_id = random.choice(rep_ids)
        
        quantity = random.randint(1, 50)
        unit_price = round(float(unit_cost) * random.uniform(1.5, 3.0), 2)
        discount = round(random.uniform(0, unit_price * 0.2), 2)
        total_amount = round((unit_price - discount) * quantity, 2)
        cost_of_goods = round(float(unit_cost) * quantity, 2)
        
        sales_data.append((
            product_id, customer_id, store_id, date_id, sales_rep_id,
            quantity, unit_price, discount, total_amount, cost_of_goods
        ))
        
        if len(sales_data) >= batch_size:
            cursor.executemany("""
                INSERT INTO fact_sales (product_id, customer_id, store_id, date_id, sales_rep_id,
                                       quantity_sold, unit_price, discount_amount, total_amount, cost_of_goods)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, sales_data)
            connection.commit()
            print(f"   Inserted {i+1:,} sales transactions...")
            sales_data = []
    
    if sales_data:
        cursor.executemany("""
            INSERT INTO fact_sales (product_id, customer_id, store_id, date_id, sales_rep_id,
                                   quantity_sold, unit_price, discount_amount, total_amount, cost_of_goods)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, sales_data)
        connection.commit()
    
    cursor.close()
    print(f"✅ Generated {num_sales:,} sales transactions!")

def main():
    print("🚀 Starting ProductCo data generation...")
    print("=" * 60)
    
    connection = connect_to_mysql()
    if not connection:
        return
    
    try:
        generate_suppliers(connection, 100)
        generate_date_dimension(connection)
        generate_products(connection, 1000)
        generate_customers(connection, 50000)
        generate_stores(connection, 200)
        generate_sales_reps(connection, 500)
        generate_sales_facts(connection, 1000000)  # 1 Million sales records!
        
        print("=" * 60)
        print("🎉 Data generation completed successfully!")
        print("📊 Database Statistics:")
        
        cursor = connection.cursor()
        tables = ['dim_supplier', 'dim_date', 'dim_product', 'dim_customer', 
                  'dim_store', 'dim_sales_rep', 'fact_sales']
        
        for table in tables:
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            count = cursor.fetchone()[0]
            print(f"   {table}: {count:,} records")
        
        cursor.close()
        
    except Exception as e:
        print(f"❌ Error during data generation: {e}")
        connection.rollback()
    finally:
        connection.close()
        print("\n🔒 Database connection closed.")

if __name__ == "__main__":
    main()
