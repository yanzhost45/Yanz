import telebot

TOKEN = "7974171410:AAHLbyCDz70jpe_T3dVnDbq9IGtekVKBedU"
bot = telebot.TeleBot(TOKEN)

@bot.message_handler(commands=['start', 'help'])
def send_welcome(message):
    bot.reply_to(message, "Hai! Aku bot.")

@bot.message_handler(func=lambda m: True)
def echo_all(message):
    bot.reply_to(message, message.text)

print("Bot jalan...")
bot.infinity_polling()
