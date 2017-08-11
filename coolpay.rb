require 'rubygems' if RUBY_VERSION < '1.9'
require 'rest_client'
require 'json'

#require 'pry'
#binding.pry

# todo:
# illegal chars


$username = "peteb"
$apikey = "A44C477DAE97B123"

$appname = "Coolpay CLI for FakeBook"

$token = ""

def confirm
    while true
        chr = $stdin.readline.strip
        case chr
            when 'y', 'Y'
                return true
            when 'n', 'N'
                return false
        end
    end
end

def login()

    values = {
      "username": "#{$username}",
      "apikey": "#{$apikey}"
    }
    headers = {
      :content_type => 'application/json'
    }

    response = RestClient.post 'https://coolpay.herokuapp.com/api/login', values, headers
    response = JSON.parse(response)
    if response['token']
        puts "authetication successful"
        $token = response['token']
    else
        puts "authetication issue, check validity of your apikey"
        exit!
    end
end

def get_transactions()
    headers = {
      :content_type => 'application/json',
      :authorization => "Bearer #{$token}"
    }

    response = RestClient.get 'https://coolpay.herokuapp.com/api/payments', headers
    response = JSON.parse(response)

    transactions = []
    if response['payments']
        transactions = response['payments']
#        puts "success, received #{transactions.length} in transactions list'"
    end
    return transactions
end

def get_recipients()
    headers = {
      :content_type => 'application/json',
      :authorization => "Bearer #{$token}"
    }

    response = RestClient.get 'https://coolpay.herokuapp.com/api/recipients', headers
    response = JSON.parse(response)

    recipients = []
    if response['recipients']
        recipients = response['recipients']
#        puts "success, received #{recipients.length} in recipients list'"
    end
    return recipients
end

def add_recipient()

    name = ""
    add = false
    while true
        puts "e[x]it | please enter the new recipient's full name: "
        input = $stdin.readline.strip
        begin
            case input
                when "x"
                    break
                when ""
                    next
                else
                    print "adding client '#{input}', please confirm [y/n]: "
                    res = confirm
                    if res
                        name = input
                        add = true
                    end
                    break
            end
        end
    end

    if add
        values = {
            "recipient": {
                "name": "#{name}"
            }
        }
        headers = {
          :content_type => 'application/json',
          :authorization => "Bearer #{$token}"
        }
        response = RestClient.get 'https://coolpay.herokuapp.com/api/recipients?name='+"#{name}", headers
        response = JSON.parse(response)
        if response['recipients'] && response['recipients'].length > 0
            recipients = response['recipients']
            puts "error trying to add recipient '#{name}', they already exist with id: '#{recipients[0]['id']}'"
        else
            response = RestClient.post 'https://coolpay.herokuapp.com/api/recipients', values, headers
            response = JSON.parse(response)
            if response['recipient']
                recipient = response['recipient']
                puts "success, added recipient '#{name}', id: '#{recipient['id']}'"
            else
                puts "error trying to add recipient, received: #{response}"
            end
        end
    end
end

def send_money()
    recipients = get_recipients()

    if recipients.nil?
        puts "no recipients to send money to. add the recipient first"
        return
    end

    input_sections = [ 'confirm', 'currency', 'amount', 'recipient' ]
    recipient = {}
    add = false
    while true
        input_section = input_sections[-1]
        input = ""
        unless input_section == "confirm"
            puts "e[x]it | please enter transation data [#{input_section}]: "
            input = $stdin.readline().strip
        end
        begin
            case input
                when "x"
                    break
                else
                    case input_section
                        when "recipient"
                            recipient = recipients.select { |x| x['id'] == input || x['name'] == input }
                            if recipient.nil?
                                puts "error, no matching recipient id or name found using search: '#{input}'"
                            else
                                recipient = recipient[0]
                                input_sections.pop
                            end
                        when "amount"
                            unless /^[0-9]+\.?[0-9]*$/.match(input)
                                puts "error, invalid amount give, required format '0.00'"
                                next
                            end
                            amount = sprintf "%.2f" % input
                            input_sections.pop
                        when "currency"
                            unless /^[a-zA-Z]{3}$/.match(input)
                                puts "error, invalid currency code, please use 3 character format only"
                                next
                            end
                            currency = input
                            input_sections.pop

                        when "confirm"
                            print "ready to send '#{amount} #{currency}' to recipient '#{recipient['name']} [#{recipient['id']}]', please confirm [y/n]: "
                            res = confirm()
                            if res
                                add = true
                            end
                            break
                    end
            end
        end
    end

    if add
        # push transaction
        values = {
            "payment": {
                "amount": "#{amount}",
                "currency": "#{currency}",
                "recipient_id": "#{recipient['id']}"
            }
        }
        headers = {
            :content_type => 'application/json',
            :authorization => "Bearer #{$token}"
        }
        response = RestClient.post 'https://coolpay.herokuapp.com/api/payments', values, headers
        response = JSON.parse(response)
        if response['payment']
            payment = response['payment']
            puts "success, payment made, transactionent id: '#{payment['id']}'"
        else
            puts "error trying to make payment, received: #{response}"
        end
    end
end

def check_transactions()
    # resolve recipient ids to names

    transactions = get_transactions()
    if transactions.nil?
        puts "no transactions found"
        return
    end
    recipients = get_recipients()
    # map
    recipients_hash = {}
    recipients.each { |r| recipients_hash[r['id']] = r }

    infos = []
    transactions.each { |t| infos << {
        "name" => recipients_hash[t['recipient_id']]['name'],
        "info" => "#{t['id']}|#{recipients_hash[t['recipient_id']]['name']}|#{t['amount']} [#{t['currency']}]|#{t['status']}"} }

    # allow results narrowing by input string
    search = infos
    buffershow = 5
    bufferpos = 1
    bufferpos2 = [search.length, buffershow].min
    buffer = search.slice(bufferpos - 1, bufferpos2)
    puts "filtering transactions on '*'\n"
    while true

        unless buffer.length == 0
            buffer.each { |i| puts "#{i['info']}" }
            puts "[showing #{bufferpos}-#{bufferpos2} of #{search.length}]\n"
        end
        print "\ne[x]it | [] next matches | modify name 'starts with' filter string: "

        input = $stdin.readline().strip
        begin
            case input
                when "x"
                    break
                when ""
                    if bufferpos2 == search.length
                        bufferpos = 1 
                        bufferpos2 = [search.length, buffershow].min
                    else
                        bufferpos = bufferpos2 + 1
                        bufferpos2 = [search.length, bufferpos + buffershow].min
                    end
                when "*"
                    search = infos
                    bufferpos = 1 
                    bufferpos2 = [search.length, buffershow].min
                else
                    search = infos.select {|i| i['name'].start_with?(input)}
                    bufferpos = 1 
                    bufferpos2 = [search.length, buffershow].min
            end
        end
        buffer = search.slice(bufferpos - 1, bufferpos2)
    end
end

def help()
    puts "#{$appname}: supported commands\n\n" +
       "  help\t: this info\n" +
       "  add\t: add recipient\n" +
       "  send\t: send recipient money\n" +
       "  check\t: check a transaction's status\n" +
       "  reset\t: clear input\n" +
       "  exit\t: exit application\n\n"
end

def reset()
    puts "welcome to #{$appname}!\n\ntype 'help' to see all user commands\n\n"
end

login()
unless $token
    puts "not authenticated, aborting"
    exit!
end

reset
invalid = 0
while true
    line = $stdin.readline().strip
    begin
        case line
            when "help"
                help()
            when "add"
                add_recipient
                reset
            when "send"
                send_money
                reset
            when "check"
                check_transactions
                reset
            when "reset"
                reset
            when "exit"
                break
            else
                invalid+=1
                if invalid > 4
                    puts "try 'help' to list all valid commands\n"
                    invalid = 0
                end
        end
    rescue => e
        puts "apologies, recovering from unanticipated error: '#{e.message}'"
    end
end
puts "thanks for using #{$appname}"

