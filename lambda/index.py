import pymysql
import os

def lambda_handler(event, context):
    try:
        conn = pymysql.connect(
            host=os.environ['DB_HOST'],
            user=os.environ['DB_USER'],
            password=os.environ['DB_PASS'],
            database=os.environ['DB_NAME'],
            connect_timeout=10
        )

        with conn.cursor() as cur:
            cur.execute(open('/var/task/encrypt_column_proc.sql').read())
            cur.execute(
                f"CALL encrypt_columns('{os.environ['TABLE_NAME']}', '{os.environ['COLUMN_LIST']}', '{os.environ['ENCRYPTION_KEY']}')"
            )
        conn.commit()
        return {"status": "Success"}
    except Exception as e:
        return {"status": "Failed", "error": str(e)}
