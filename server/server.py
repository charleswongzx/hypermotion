from flask import Flask, jsonify
from flask import request
import sqlite3

app = Flask(__name__)
conn = None


def init_db():
    global conn
    conn = sqlite3.connect('packery.db', isolation_level=None)
    table_exists = "SELECT name FROM sqlite_master WHERE type='table' AND name='packages';"
    create_table = '''CREATE TABLE packages (
                                            id integer,
                                            name text,
                                            width real,
                                            height real,
                                            depth real,
                                            weight real,
                                            rotatable numeric,
                                            fragile numeric,
                                            stackable numeric,
                                            posX real,
                                            posY real,
                                            posZ real 
                                            )'''

    if not conn.execute(table_exists).fetchone():
        conn.execute(create_table)

    return conn


def add_to_db(content):
    global conn

    row = []
    row.append(content['id'])
    row.append(content['name'])
    row.append(content['dim1'])
    row.append(content['dim2'])
    row.append(content['dim3'])
    row.append(content['weight'])
    row.append(content['rotatable'])
    row.append(content['fragile'])
    row.append(content['stackable'])

    sql = '''INSERT INTO packages VALUES (?,?,?,?,?,?,?,?,?,0.0,0.0,0.0)'''

    c = conn.cursor()
    c.execute(sql, row)

    print('RowID:', c.lastrowid)

    return c.lastrowid


def dict_factory(cursor, row):
    d = {}
    for idx, col in enumerate(cursor.description):
        d[col[0]] = row[idx]
    return d


def get_from_db():
    global conn
    conn.row_factory = dict_factory
    c = conn.cursor()
    c.execute('''SELECT * FROM packages''')
    # print(c.fetchone())

    try:
        packages = []

        rows = c.fetchall()
        for row in rows:
            print(row)
            row['position'] = (row['posX'], row['posY'], row['posZ'])
            row.pop('posX')
            row.pop('posY')
            row.pop('posZ')
            # TODO: fetch, optimise and add position to each box
            # consider just placing dummy position values
            packages.append(row)

        # jsonStr = json.dumps(packages)
        json_payload = jsonify(items=packages)

        return json_payload

    except:
        return 'DB retrieval failed'


@app.route('/')
def hello_world():
    return 'hello world'


@app.route('/upload', methods=['POST'])
def upload():
    content = request.get_json(silent=False)
    print(content)
    try:
        add_to_db(content)
        return "Received and added to DB"
    except:
        print('Error with payload')
        return "Request failed, error with payload."


@app.route('/retrieve', methods=['GET'])
def retrieve():
    packages = get_from_db()
    return packages


def add_test_package():
    payload = {
        "id": 1,
        "name": "TEST ITEM",
        "dim1": 50,
        "dim2": 20,
        "dim3": 30,
        "weight": 20,
        "rotatable": 'true',
        "fragile": 'false',
        "stackable": 'true'
    }

    add_to_db(payload)

init_db()
