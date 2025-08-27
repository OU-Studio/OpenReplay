FROM node:20-alpine

WORKDIR /app

# copy package files
COPY package*.json ./

# install dependencies (use npm install if no package-lock.json)
RUN npm install --omit=dev

# copy the rest of your code
COPY . .

ENV PORT=8080
EXPOSE 8080

CMD ["npm", "start"]
