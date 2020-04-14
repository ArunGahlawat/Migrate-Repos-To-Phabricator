import csv
from selenium import webdriver
import base64, os, datetime, json,io


def set_chrome_options():
    chrome_options = webdriver.ChromeOptions()
    preferences = {
        "credentials_enable_service": False,
        'profile': {
            'password_manager_enabled': False
        }}
    chrome_options.add_argument("disable-infobars")
    chrome_options.add_argument("disable-notifications")
    chrome_options.add_experimental_option("excludeSwitches", ['enable-automation'])
    chrome_options.add_experimental_option("prefs", preferences)
    return chrome_options


def get_csv_length(filename):
    length = 0
    with open(filename, 'r') as csvfile:
        reader = csv.reader(csvfile)
        for row in reader:
            length += 1
        return length


def read_from_csv(filename):
    data = []
    with open(filename, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',')
        for row in reader:
            data.append(row)
    return data


def read_from_csv_as_dict(filename):
    data = []
    with open(filename, 'r') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            data.append(row)
    return data


def write_in_csv(filename, data, source='dict', write_mode='a'):
    if data is None:
        return
    len = get_csv_length(filename)
    with open(filename, write_mode) as csvfile:
        if source == 'list':
            writer = csv.writer(csvfile)
        else:
            writer = csv.DictWriter(csvfile, fieldnames=data.keys())
        if len == 0 and source == 'dict':
            writer.writeheader()
        writer.writerow(data)


def encode(plainText):
    return base64.encodebytes(str.encode(plainText, 'latin-1'))


def decode(encodedText):
    return base64.decodebytes(str.encode(encodedText, 'latin-1')).decode('latin-1')


def is_present_in_dictionary(current_dict, key):
    if key in current_dict:
        return True
    return False


def string_contains(parent_string,search_string):
    return search_string in parent_string


def find_in_string(parent_string,search_string):
    return parent_string.find(search_string)


def get_absolute_path(relative_path):
    return os.path.abspath(relative_path)


def format_date_time(in_date, current_format='%d/%m/%Y', new_format='%m/%d/%y'):
    return datetime.datetime.strptime(in_date, current_format).strftime(new_format)


def parse_paytm_csv(txn_date, activity, src, wallet_id, comment, debit, credit):
    parsed_txn_date = format_date_time(str(txn_date).split(" ")[0].strip())
    parsed_source = ""
    parsed_comment = ""
    parsed_category = ""
    parsed_amount = 0.0
    parsed_txn_type = "credit"
    activity = str(activity).title().strip()
    src = str(src)
    parsed_order_no = src
    comment = str(comment)
    parsed_debit = 0.0
    parsed_credit = 0.0
    if debit and debit != '':
        parsed_debit = float(debit)
    if credit and credit != '':
        parsed_credit = float(credit)
    valid_activity = ["Paid For Order","Cashback Received","Payment Received","Money Sent","Refund For Order","Paytm Cash Sent"]
    if activity in valid_activity:
        if parsed_credit > 0:
            parsed_amount = parsed_amount + parsed_credit
        if parsed_debit > 0:
            parsed_amount = parsed_amount - parsed_debit
        if parsed_amount < 0:
            parsed_txn_type = "debit"
            parsed_amount = parsed_amount * -1
        parsed_source_index = src.find(" Order #", 1)
        if parsed_source_index > 0:
            parsed_source = src.split(" Order #", 1)[0]
            parsed_order_no = src.split(" Order #", 1)[1]
        parsed_comment_index = comment.find(" To: ")
        if parsed_comment_index > 0:
            if parsed_txn_type == "debit":
                parsed_comment = comment.split(" To: ", 1)[1]
            else:
                parsed_comment = comment.split(" To: ", 1)[0].replace("From: ", "")
        if parsed_source == "" and parsed_comment != "":
            parsed_source = parsed_comment
        if parsed_source == "" and activity == "Cashback Received":
            parsed_source = "Paytm"
            parsed_category = "Cashback"
        parsed_comment = "Wallet Txn ID: "+str(wallet_id)+" | Order #: "+parsed_order_no
        if comment is not None and comment.strip() != "":
            parsed_comment = parsed_comment+" | Comment: "+comment
        if parsed_source is not None and parsed_source.strip() == "":
            parsed_source = "Paytm Transfer"
        parsed_dict = {
            "Date" : parsed_txn_date,
            "Activity" : activity,
            "Description" : parsed_source.title().strip(),
            "Category" : parsed_category,
            "Amount" : parsed_amount,
            "Notes" : parsed_comment.title().strip(),
            "Source" : "paytm",
            "Type" : parsed_txn_type
        }
        return parsed_dict


def construct_map_from_txn_csv(filename):
    parsed_map_description_to_merchant = {}
    parsed_map_merchant_to_category = {}
    with open('Mappings/description_to_merchant_map.json') as f:
        data = json.load(f)
    if data is not None and issubclass(type(data),dict) and len(data)>0:
        parsed_map_description_to_merchant = data.copy()
    with open('Mappings/merchant_to_category_map.json') as f:
        data = json.load(f)
    if data is not None and issubclass(type(data),dict) and len(data) > 0:
        parsed_map_merchant_to_category = data.copy()
    data = read_from_csv_as_dict(filename)
    if data is None or len(data) < 1:
        return
    for row in data:
        if row is None or not issubclass(type(row),dict):
            continue
        if "Description" not in row or "Category" not in row:
            continue
        if str(row["Category"]).strip() == "":
            row["Category"] = "Uncategorized"
        if row["Description"] is not None and str(row["Description"]).strip() != "":
            if row["Description"] in parsed_map_description_to_merchant:
                continue
            else:
                parsed_map_description_to_merchant[row["Description"]] = row["Description"]
                if row["Description"] in parsed_map_merchant_to_category:
                    continue
                else:
                    parsed_map_merchant_to_category[row["Description"]] = row["Category"]
    if len(parsed_map_description_to_merchant) > 0:
        with open('Mappings/description_to_merchant_map.json', 'w') as f:
            json.dump(parsed_map_description_to_merchant, f,indent=4,sort_keys=True)
    if len(parsed_map_merchant_to_category) > 0:
        with open('Mappings/merchant_to_category_map.json', 'w') as f:
            json.dump(parsed_map_merchant_to_category, f,indent=4,sort_keys=True)
    print("done")


def map_merchant_and_category_from_json(filename,target_file):
    parsed_map_description_to_merchant = {}
    parsed_map_merchant_to_category = {}
    with open('Mappings/description_to_merchant_map.json') as f:
        data = json.load(f)
    if data is not None and issubclass(type(data), dict) and len(data) > 0:
        parsed_map_description_to_merchant = data.copy()
    with open('Mappings/merchant_to_category_map.json') as f:
        data = json.load(f)
    if data is not None and issubclass(type(data), dict) and len(data) > 0:
        parsed_map_merchant_to_category = data.copy()
    if parsed_map_description_to_merchant is None or parsed_map_merchant_to_category is None:
        return
    data = read_from_csv_as_dict(filename)
    if data is None or len(data) < 1:
        return
    for row in data:
        if row is None or not issubclass(type(row), dict):
            continue
        data_to_write = {}
        if "Date" not in row or "Activity" not in row or "Description" not in row or "Category" not in row \
                or "Amount" not in row or "Notes" not in row or "Source" not in row or "Type" not in row:
            continue
        if row["Date"] is not None and str(row["Date"]).strip() != "" \
                and row["Activity"] is not None and str(row["Activity"]).strip() != "" \
                and row["Description"] is not None and str(row["Description"]).strip() != "" \
                and row["Amount"] is not None and str(row["Activity"]).strip() != "" \
                and row["Source"] is not None and str(row["Source"]).strip() != "" \
                and row["Type"] is not None and str(row["Type"]).strip() != "":
            if row["Description"] not in parsed_map_description_to_merchant:
                continue
            merchant = parsed_map_description_to_merchant[row["Description"]]
            if merchant not in parsed_map_merchant_to_category:
                continue
            category = parsed_map_merchant_to_category[merchant]
            data_to_write["Date"] = row["Date"]
            data_to_write["Description"] = merchant
            data_to_write["Category"] = category
            data_to_write["Amount"] = row["Amount"]
            data_to_write["Notes"] = row["Notes"]
            data_to_write["Source"] = row["Source"]
            data_to_write["Type"] = row["Type"]
            write_in_csv(target_file,data_to_write)
