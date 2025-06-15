import subprocess
import sys
import os

# --- 1. Install necessary libraries if not already installed ---
try:
    import mysql.connector
except ImportError:
    print("mysql-connector-python not found. Installing...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "mysql-connector-python"])
    import mysql.connector

try:
    import pandas as pd
except ImportError:
    print("pandas not found. Installing...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pandas"])
    import pandas

print("Required libraries are installed.")

# --- 2. Database Connection Details ---
# IMPORTANT: Replace these with your actual MySQL database credentials
DB_CONFIG = {
    'host': '127.0.0.1',  # Or your MySQL server IP/hostname
    'user': 'root',  # Your MySQL username (e.g., 'root')
    'password': 'Your_Password',  # Your MySQL password
    'database': 'schema_name'  # The database name you want to use
}

# --- 3. SQL CREATE TABLE Statements ---
# Tables are ordered to respect foreign key dependencies
CREATE_TABLE_QUERIES = [
    """
    CREATE TABLE IF NOT EXISTS Customers (
        Customer_ID INT PRIMARY KEY,
        FirstName VARCHAR(255),
        LastName VARCHAR(255),
        PhoneNumber VARCHAR(20),
        City VARCHAR(100),
        Gender VARCHAR(50),
        Religion VARCHAR(50)
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS Stores (
        StoreID INT PRIMARY KEY,
        Address VARCHAR(255),
        City VARCHAR(100),
        PhoneNumber VARCHAR(20),
        OpeningDate DATE
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS Products (
        Product_ID VARCHAR(10) PRIMARY KEY,
        ProductName VARCHAR(255),
        Category VARCHAR(100),
        Brand VARCHAR(100),
        Price DECIMAL(10, 2),
        Cost DECIMAL(10, 2),
        Color VARCHAR(50),
        Material VARCHAR(50)
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS Sizes (
        Size_ID INT PRIMARY KEY,
        SizeName VARCHAR(50),
        NumericSize DECIMAL(4, 1),
        SizeType VARCHAR(50)
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS Employees (
        EmployeeID INT PRIMARY KEY,
        FirstName VARCHAR(255),
        LastName VARCHAR(255),
        Role VARCHAR(100),
        StoreID INT,
        HireDate DATE,
        Salary DECIMAL(10, 2),
        Gender VARCHAR(50),
        Religion VARCHAR(50),
        FOREIGN KEY (StoreID) REFERENCES Stores(StoreID)
    );
    """,
    # Payments table must be created before Sales due to Sales having Payment_ID as FK
    """
    CREATE TABLE IF NOT EXISTS Payments (
        Payment_ID INT PRIMARY KEY,
        Sale_ID INT,
        PaymentMethod VARCHAR(100),
        PaymentAmount DECIMAL(10, 2),
        PaymentDate DATE,
        PaymentTime TIME
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS Sales (
        Sale_ID INT PRIMARY KEY,
        Customer_ID INT,
        Store_ID INT,
        Employee_ID INT,
        SaleDate DATE,
        SaleTime TIME,
        TotalAmount DECIMAL(10, 2),
        PaymentStatus VARCHAR(50),
        Payment_ID INT, -- Foreign key to Payments table
        FOREIGN KEY (Customer_ID) REFERENCES Customers(Customer_ID),
        FOREIGN KEY (Store_ID) REFERENCES Stores(StoreID),
        FOREIGN KEY (Employee_ID) REFERENCES Employees(EmployeeID),
        FOREIGN KEY (Payment_ID) REFERENCES Payments(Payment_ID)
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS Sale_Items (
        Sale_Item_ID INT PRIMARY KEY,
        Sale_ID INT,
        Product_ID VARCHAR(10),
        Size_ID INT,
        Quantity INT,
        FOREIGN KEY (Sale_ID) REFERENCES Sales(Sale_ID),
        FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID),
        FOREIGN KEY (Size_ID) REFERENCES Sizes(Size_ID)
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS Returns (
        Return_ID INT PRIMARY KEY,
        Sale_ID INT,
        Product_ID VARCHAR(10),
        Size_ID INT,
        QuantityReturned INT,
        ReturnAmount DECIMAL(10, 2),
        ReturnDate DATE,
        ReturnTime TIME,
        Reason VARCHAR(255),
        FOREIGN KEY (Sale_ID) REFERENCES Sales(Sale_ID),
        FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID),
        FOREIGN KEY (Size_ID) REFERENCES Sizes(Size_ID)
    );
    """
]

# --- 4. Mapping CSV files to SQL Tables and their respective columns for insertion ---
# The order of these files in the list is crucial for successful foreign key insertion.
CSV_FILES_TO_INSERT = [
    'Customers.csv',
    'Stores.csv',
    'Products.csv',
    'Sizes.csv',
    'Employees.csv',
    'Payments.csv', # Insert Payments before Sales
    'Sales.csv',
    'Sale_Items.csv',
    'Returns.csv'
]

CSV_TO_TABLE_MAPPING = {
    'Customers.csv': {
        'table_name': 'Customers',
        'columns': ['Customer_ID', 'FirstName', 'LastName', 'PhoneNumber', 'City', 'Gender', 'Religion']
    },
    'Stores.csv': {
        'table_name': 'Stores',
        'columns': ['StoreID', 'Address', 'City', 'PhoneNumber', 'OpeningDate']
    },
    'Products.csv': {
        'table_name': 'Products',
        'columns': ['Product_ID', 'ProductName', 'Category', 'Brand', 'Price', 'Cost', 'Color', 'Material']
    },
    'Sizes.csv': {
        'table_name': 'Sizes',
        'columns': ['Size_ID', 'SizeName', 'NumericSize', 'SizeType'
        ]
    },
    'Employees.csv': {
        'table_name': 'Employees',
        'columns': ['EmployeeID', 'FirstName', 'LastName', 'Role', 'StoreID', 'HireDate', 'Salary', 'Gender', 'Religion']
    },
    'Payments.csv': {
        'table_name': 'Payments',
        'columns': ['Payment_ID', 'Sale_ID', 'PaymentMethod', 'PaymentAmount', 'PaymentDate', 'PaymentTime']
    },
    'Sales.csv': {
        'table_name': 'Sales',
        'columns': ['Sale_ID', 'Customer_ID', 'Store_ID', 'Employee_ID', 'SaleDate', 'SaleTime', 'TotalAmount', 'PaymentStatus', 'Payment_ID']
    },
    'Sale_Items.csv': {
        'table_name': 'Sale_Items',
        'columns': ['Sale_Item_ID', 'Sale_ID', 'Product_ID', 'Size_ID', 'Quantity']
    },
    'Returns.csv': {
        'table_name': 'Returns',
        'columns': ['Return_ID', 'Sale_ID', 'Product_ID', 'Size_ID', 'QuantityReturned', 'ReturnAmount', 'ReturnDate', 'ReturnTime', 'Reason']
    }
}

# --- 5. Main function to connect, create tables, and insert data ---
def insert_data_to_mysql(db_config, create_queries, csv_files_order, csv_mapping, csv_dir=r'C:\Users\justt\Desktop\bata sample\p-7\csv'):
    """
    Connects to MySQL, creates tables, and inserts data from CSV files.
    """
    connection = None
    try:
        # Establish connection
        print("\nConnecting to MySQL database...")
        connection = mysql.connector.connect(**db_config)
        cursor = connection.cursor()
        print("Successfully connected to MySQL database.")

        # Create Database if it doesn't exist (optional, can be done manually)
        # It's generally safer to create the database manually first
        # cursor.execute(f"CREATE DATABASE IF NOT EXISTS {db_config['database']}")
        # connection.database = db_config['database'] # Select the database

        # --- Create Tables ---
        print("\nCreating tables...")
        for query in create_queries:
            try:
                cursor.execute(query)
                print(f"Executed CREATE TABLE query for: {query.split()[5]}...")
            except mysql.connector.Error as err:
                print(f"Error creating table: {err} (Query: {query.splitlines()[0].strip()})")
                # Continue to next table, but log the error

        connection.commit() # Commit table creations
        print("Tables created successfully (or already exist).")

        # --- Insert Data from CSVs ---
        print("\nInserting data into tables...")
        for csv_filename in csv_files_order:
            file_path = os.path.join(csv_dir, csv_filename)
            
            if not os.path.exists(file_path):
                print(f"Warning: CSV file not found: {file_path}. Skipping insertion for this table.")
                continue

            table_info = csv_mapping.get(csv_filename)
            if not table_info:
                print(f"Warning: No mapping found for {csv_filename}. Skipping.")
                continue

            table_name = table_info['table_name']
            columns = table_info['columns']

            print(f"Reading {csv_filename} and inserting into {table_name}...")
            
            try:
                df = pd.read_csv(file_path)
                # Ensure DataFrame columns match the target SQL columns and handle missing/extra columns
                df = df[columns] # Select only the columns relevant for insertion

                # Convert date columns based on the table - Returns needs special handling
                date_columns = ['ReturnDate', 'PaymentDate', 'SaleDate', 'HireDate', 'OpeningDate']
                for col in date_columns:
                    if col in df.columns:
                        if table_name == 'Returns' and col == 'ReturnDate':
                            # Explicitly specify the date format as day/month/year for Returns table
                            df[col] = pd.to_datetime(df[col], errors='coerce', format='%d/%m/%Y').dt.strftime('%Y-%m-%d')
                        else:
                            # For other tables, use flexible date parsing
                            df[col] = pd.to_datetime(df[col], errors='coerce').dt.strftime('%Y-%m-%d')

                # Prepare the INSERT statement
                cols_str = ', '.join(columns)
                placeholders = ', '.join(['%s'] * len(columns))
                insert_query = f"INSERT INTO {table_name} ({cols_str}) VALUES ({placeholders})"

                # Insert data row by row
                for index, row in df.iterrows():
                    try:
                        # Convert pandas NaT to None for SQL NULL
                        values = [None if pd.isna(val) else val for val in row.values]
                        cursor.execute(insert_query, tuple(values))
                    except mysql.connector.Error as err:
                        print(f"Error inserting row into {table_name}: {err} (Row: {row.to_dict()})")
                        # You might want to log this or decide to abort based on severity
                        connection.rollback() # Rollback current transaction on error
                        break # Stop inserting for this table if one row fails
                
                connection.commit() # Commit changes after each file
                print(f"Finished inserting data for {table_name}.")

            except Exception as e:
                print(f"An error occurred during data insertion for {csv_filename}: {e}")
                connection.rollback() # Rollback any partial insertions for this table

    except mysql.connector.Error as err:
        print(f"MySQL Error: {err}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
    finally:
        if connection and connection.is_connected():
            cursor.close()
            connection.close()
            print("MySQL connection closed.")

# --- Run the data insertion process ---
if __name__ == "__main__":
    # Use the correct path to your CSV files
    csv_data_directory = r'C:\Users\justt\Desktop\bata sample\p-7\csv'
    
    # You MUST change the DB_CONFIG details above to your actual MySQL credentials.
    print("--- Starting MySQL Data Insertion ---")
    insert_data_to_mysql(DB_CONFIG, CREATE_TABLE_QUERIES, CSV_FILES_TO_INSERT, CSV_TO_TABLE_MAPPING, csv_data_directory)
    print("--- MySQL Data Insertion Process Complete ---")

