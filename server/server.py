from flask import Flask, json, jsonify
from flask import request
import sqlite3


app = Flask(__name__)

# def post_dimensions(payload):
#     r = requests.post(' https://svfjld11of.execute-api.ap-southeast-1.amazonaws.com/prod/cargo-management', params=payload)
#     return r


# TODO:
# receive json from upload x
# convert to dict x
# upload dict to sqlite db x
# implement func to draw all pax from db x
# optimisation func to place all pax from db
# GET call to give id, dimensions, rotatable, fragile, stackable, dangerous as json

conn = None


def init_db():
    global conn
    conn = sqlite3.connect('packery.db', isolation_level=None)
    table_exists = "SELECT name FROM sqlite_master WHERE type='table' AND name='packages';"
    create_table = '''CREATE TABLE packages (
                                            id integer,
                                            name text,
                                            dim1 real,
                                            dim2 real,
                                            dim3 real,
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
    content = request.get_json(silent=True)
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





# @app.route('/submit', methods=['POST'])
# def submit():
#     content = request.get_json(silent=True)
#
#     dim1 = content['dim1']
#     dim2 = content['dim2']
#     dim3 = content['dim3']
#     iden = content['id']
#     weight = content['weight']
#     rotatable = content['rotatable']
#     fragile = content['fragile']
#     stackable = content['stackable']
#
#     payload = {
#         "id": iden,
#         "name": iden,
#         "width": dim1,
#         "height": dim2,
#         "depth": dim3,
#         "weight": weight,
#         "rotatable": rotatable,
#         "fragile": fragile,
#         "stackable": stackable
#     }
#
#     print('Sending payload to server..')
#     r = post_dimensions(payload)
#     print('Payload sent:\n', r.text)
#
#     return "Received"


# def compute(request):
#     print(request.args.get('string','')) #get data from post request here
#     int = subprocess.call(["ls", "-l"]) # call cpp exec here
#     return str(int)

# payload = {
#     "id": 1,
#     "name": "item",
#     "width": 50,
#     "height": 20,
#     "depth": 30,
#     "weight": 20,
#     "rotatable": 'true',
#     "fragile": 'false',
#     "stackable": 'true'
# }

#post_dimensions(payload)
