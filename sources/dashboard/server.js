const express = require('express');
const Chance = require('chance');
const app = express();
var chance = new Chance();

const createRandomData = () => {
  const numberOfShipping = Math.floor(Math.random() * 20) + 1;
  let data = [];
  for (let i = 0; i < numberOfShipping; i++) {
    const jsonData = {
      shipment_id: chance.guid(),
      driver_id: chance.guid(),
      trip_type: Math.floor(Math.random() * 2),
      confirm_at: chance.date({string: true}) + ' ' + chance.hour({twentyfour: true}) + ':' + chance.minute() + ':' + chance.second(),
      ship_at: chance.date({string: true}) + ' ' + chance.hour({twentyfour: true}) + ':' + chance.minute() + ':' + chance.second(),
      complete_at: chance.date({string: true}) + ' ' + chance.hour({twentyfour: true}) + ':' + chance.minute() + ':' + chance.second(),
      distance: (Math.random() * 100)
    }
    data.push(jsonData);
  }
  return data;
}

app.get('/', (req, res) => {
  const data = JSON.stringify(createRandomData());
  res.setHeader('Content-Type', 'application/json');
  res.send(
    data
  );
});



app.listen(3000, () => console.log('Example app is listening on port 3000.'));