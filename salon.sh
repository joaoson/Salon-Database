#! /bin/bash

echo "Welcome to Joao's Salon"

PSQL="psql --username=postgres --dbname=salon -t --no-align -c"
SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id;")
printf "What service would you like to have?\n\n"

echo "$SERVICES" | while IFS='|' read -r service_id SERVICE_NAME
do
  echo "$service_id) $SERVICE_NAME"
done
read SERVICE_ID_SELECTED

while ! [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]] || ! echo "$SERVICES" | grep -q "^$SERVICE_ID_SELECTED|"; do
  echo "Invalid selection. Please choose one of our services"
  echo "$SERVICES" | while IFS='|' read -r SERVICE_ID SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done
  read SERVICE_ID_SELECTED
done

SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id='$SERVICE_ID_SELECTED'")

printf "What's your phone number?"
read CUSTOMER_PHONE


result=$($PSQL "SELECT name,customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

IFS='|' read -r CUSTOMER_NAME CUSTOMER_ID <<< "$result"

if [[ -z $CUSTOMER_NAME ]]; then
  echo "Contact does not exist"
  read CUSTOMER_NAME

  INSERT_CUSTOMER=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE') RETURNING customer_id" | awk 'NR==1 {print $1}')

  if [[ -n $INSERT_CUSTOMER ]]; then
      CUSTOMER_ID=$INSERT_CUSTOMER
      echo "Inserted customer $CUSTOMER_NAME with ID $CUSTOMER_ID"
  else
      echo "Failed to insert customer"
      exit 1
  fi
fi

echo "What time would you like your cut, $CUSTOMER_NAME?"

read SERVICE_TIME
printf "Service ID Selected: %s\n" "$SERVICE_ID_SELECTED"
printf "Customer ID: %s\n" "$CUSTOMER_ID"
printf "Service Time: %s\n" "$SERVICE_TIME"


INSERT_Appointment=$($PSQL "INSERT INTO appointments(service_id, customer_id, time) VALUES($SERVICE_ID_SELECTED, $CUSTOMER_ID, '$SERVICE_TIME')")

if [[ $INSERT_Appointment == "INSERT 0 1" ]]; then
  echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
else
  echo "Failed to schedule appointment. Error: $INSERT_Appointment"
  exit 1
fi
