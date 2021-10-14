var AWS = require("aws-sdk");
AWS.config.update({ region: process.env.AWS_REGION });

var ddb = new AWS.DynamoDB({ apiVersion: "2012-08-10" });

const getParams = {
  TableName: process.env.DYNAMODB_TABLE,
  Key: {
    COUNTER: { S: "OrderEvents" }
  }
};

const saleParams = name => ({
  TableName: process.env.DYNAMODB_TABLE,
  Key: {
    COUNTER: { S: "OrderEvents" }
  },
  UpdateExpression: "set EVENTS.#name = EVENTS.#name + :val",
  ExpressionAttributeNames: {
    "#name": name
  },
  ExpressionAttributeValues: {
    ":val": { N: "1" }
  },
  ReturnValues: "UPDATED_NEW"
});

const getCountOfSold = async () => {
  const result = await ddb.getItem(getParams).promise();

  const placed = read("vehicleSold", result);
  const cancelled = read("vehicleSaleCancelled", result);
  return placed - cancelled;
};

const read = (name, item) => {
  try {
    const val = item.Item.EVENTS.M[name].N;
    return parseInt(val);
  } catch (e) {
    console.log(e);
    return 0;
  }
};

const updateVehicleSales = async eventName => {
  try {
    const result = await ddb.updateItem(saleParams(eventName)).promise();
    console.log(result);
  } catch (e) {
    console.log(e);
  }
};

module.exports = {
  getCountOfSold,
  updateVehicleSales
};