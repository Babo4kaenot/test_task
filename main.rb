require          'watir' 
require          'nokogiri'
require          'pry'
require_relative 'transactions'

class Moldindconbank
  attr_reader :browser

  def initialize
    @browser = Watir::Browser.new(:chrome)
  end

  def main
    log_in
    result = get_cards_info
    log_out
    
    result
  end

private

  def log_in
    browser.goto("https://wb.micb.md")
    change_language
    wait_element(browser.text_field(class: "username") && browser.text_field(id: "password"))

    # puts "Please, enter your username: \n"
    # username = gets.chomp
    browser.text_field(class: "username").click
    browser.text_field(class: "username").set("Babo4kaenot")

    # puts "Please, enter your password: \n"
    # password = gets.chomp
    browser.text_field(id: "password").click
    browser.text_field(id: "password").set("Stanislavept155")

    wait_element(browser.button(class: "wb-button"))
    browser.button(class: "wb-button").click
    sleep 2
    if browser.div(class: ["page-message", "error"]).present?
      raise "Incorrect Login or Password"
    end
  end

  def get_cards_info
    wait_element(browser.div(class: "contract-cards"))
    cards = []
    transactions = []

    browser.divs(class: "contract-cards").each do |link|
      sleep 2
      binding.pry
      link.click

      wait_element(browser.link(class: "ui-tabs-anchor", text: "Информация"))
      browser.link(class: "ui-tabs-anchor", text: "Информация").click

      wait_element(browser.div(id: "contract-information").table.tbody)
      card = Nokogiri::HTML(browser.div(id: "contract-information").table.tbody.html)

      wait_element(browser.link(class: "menu-link", text: "Карты и счета"))
      browser.link(class: "menu-link", text: "Карты и счета").click

      cards << {
        name:     card.css('tr td.value')[0].text.to_s,
        balance:  card.css('tr td.value')[8].text.to_f,
        currency: card.css('tr td.value')[8].text.split(" ").last,
        nature:   card.css('tr td.value')[3].text.split("- ").last
      }

      transactions << path_to_transactions
    end
  end

  def path_to_transactions
    # wait_element(browser.link(class: "menu-link", text: "Карты и счета"))
    # browser.link(class: "menu-link", text: "Карты и счета").click

    # wait_element(browser.div(class: "contract-cards"))
    # browser.div(class: "contract-cards").click

    wait_element(browser.link(class: "ui-tabs-anchor", text: "История транзакций"))
    browser.link(class: "ui-tabs-anchor", text: "История транзакций").click
    sleep 3

    if browser.h1(text: /Нет операций для отображения/i).present?
      browser.link(class: "menu-link", text: "Карты и счета").click
      wait_element(browser.div(class: "contract-cards"))
      sleep 3
      return 
    end

    wait_element(browser.div(class: ["filter", "filter_period"]))
    browser.div(class: ["filter", "filter_period"]).input.click

    wait_element(browser.link(class: "ui-state-default", text: "1"))
    browser.link(class: "ui-state-default", text: "1").click

    get_transactions_info
  end

  def get_transactions_info
    transactions = []

    browser.links(class: "operation-details").each do |en|
      en.click
      wait_element(browser.div(id: "operation-details-dialog"))
      sleep 0.5

      transactions_info = Nokogiri::HTML(browser.div(id: "operation-details-dialog").html)

      date        = transactions_info.at_css(".operation-details-body").at_css(".details").at_css(".value").text
      description = transactions_info.at_css(".operation-details-header").text
      amount      = transactions_info.at_css(".operation-details-body").css(".details").last.at_css(".value").text

      browser.send_keys :escape

      transactions << Transactions.new(date, description, amount).to_hash
    end

    transactions
  end

  def wait_element(element)
    Watir::Wait.until { element.present? }
  end

  def change_language
    wait_element(browser.li(class: ["language-item", "ru"]))
    browser.li(class: ["language-item", "ru"]).click
  end

  def log_out 
    wait_element(browser.link(id: "logout"))
    browser.link(id: "logout").click
  end
end

webbanking = Moldindconbank.new
puts JSON.pretty_generate(webbanking.main)
