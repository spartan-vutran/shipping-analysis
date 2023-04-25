const express = require('express');
const Chance = require('chance');
const app = express();
var chance = new Chance();

const processISODate = (isoDate) => {
  return isoDate.toISOString().slice(0,-5).replace('T', ' ');
}

function expect_at_generation(confirm_date, distance){
  if(distance>0 && distance <=3){
    const minutes = Math.random() * 10 + 5;
    return new Date(confirm_date.getTime() + minutes*60000);
  } else if(distance>3 && distance <=10){
    const minutes = Math.random() * 20 + 10;
    return new Date(confirm_date.getTime() + minutes*60000);
  } else {
    const minutes = Math.random() * 30 + 20;
    return new Date(confirm_date.getTime() + minutes*60000);
  }
}

function ship_cost_calculation(distance, trip_type){
  let cost = 0;
  if(distance>0 && distance <=3){
    cost =  0.5;
  } else if(distance>3 && distance <=10){
    cost = 2.0;
  } else {
    cost = 2.0 + (distance-10)*1;
  }

  return cost + (trip_type == 1)? (Math.random() + 0.5)* cost: 0;
}


function get_region(){
  region_list = ["yen bai", "vinh phuc", "vinh long", "tuyen quang", "tra vinh", "thua thien hue", "tien giang", "thanh hoa", "thai nguyen", "thai binh", "tay ninh"]

  return region_list[Math.floor(Math.random()*region_list.length)]
}



const createRandomData = () => {
  const numberOfShipping = 100;
  let data = [];
  const min_confirm = new Date('2022-01-01T00:00:00');
  const max_confirm = new Date('2023-12-01T00:00:00');

  for (let i = 0; i < numberOfShipping; i++) {
    const distance = Math.floor(Math.random() * 30) + 1;
    const confirm_at = chance.date({min: min_confirm, max: max_confirm});
    const expect_at = expect_at_generation(confirm_at,distance);
    const relative_minute = Math.floor(Math.random() * 10) -5;
    const complete_at = new Date(expect_at.getTime() + relative_minute*60000);

    const total_unit = Math.floor(Math.random() * 20) + 5;
    const ship_unit = (Math.random()>0.1)?total_unit: total_unit - Math.floor(Math.random() * 5) - 1;
    const trip_type = Math.floor(Math.random() * 2)

    const jsonData = {
      shipment_id: chance.guid(),
      driver_id: chance.guid(),
      trip_type,
      confirm_at: processISODate(confirm_at),
      complete_at: processISODate(complete_at),
      expect_at: processISODate(expect_at),
      distance,
      address: chance.address(),
      region: get_region(),
      country: "Vietnam",
      ship_cost: ship_cost_calculation(distance, trip_type),
      ship_volume: (Math.random()*30 + 1).toFixed(2),
      total_unit,
      ship_unit,
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