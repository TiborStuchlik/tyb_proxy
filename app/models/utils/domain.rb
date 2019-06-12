module Utils::Domain

  require "mechanize"
  require 'json'

  def init_dns
    puts "DNS updater v 1.0"

    @url = 'https://www.domainmaster.cz/'
    username = 'UUU'
    password = 'PPP'

    a = Mechanize.new {|agent|
      agent.user_agent = 'TYBOT'
    }

    puts "login..."
    p = a.get(@url + 'prihlaseni/')
    login = p.form(id: 'login_form')
    login.idacc = username
    login.password = password
    lr = a.submit(login, login.buttons.first)
    puts "loged to domainmaster"
    @a = a
  end

  def update_dns( d, v)
    dns = @a.get(@url + d.sub('/','') + '&__xhr_request=1')
    f = dns.body.scan(/<form.*<\/form>/).last

    jsf = JSON.parse('"' + f + '"')
    data = Mechanize::Form.new(Nokogiri::XML(jsf).root, @a)
    data.ttl = 60
    data.data = v
    @a.agent.request_headers = {"X-Requested-With" => "XMLHttpRequest"}
    dr = @a.submit(data, data.buttons.first)
  end

  def parse_dns(domain)
    da = domain.split('.')
    rd = ([] << da.delete_at(-2) << da.delete_at(-1)).join('.')
    da = (['_acme-challenge'] + da).join('.')
    fn = da + "." + rd
    [fn,da,rd]
  end

  def create_dns( domain, value)
    fn,da,rd = parse_dns(domain)
    url = @url + "cs/dns/add_txt_record/?domain=#{rd}&__xhr_request=1"
    #@a.agent.request_headers = {"X-Requested-With" => "XMLHttpRequest", "Referer" => "https://www.domainmaster.cz/cs/dns/detail/?domain=#{rd}"}
    dns = @a.get(url)
    f = dns.body.scan(/<form.*<\/form>/).last
    jsf = JSON.parse('"' + f + '"')
    data = Mechanize::Form.new(Nokogiri::XML(jsf).root, @a)
    data.fields[0].value = da
    data.value = value
    @a.agent.request_headers = {"X-Requested-With" => "XMLHttpRequest"}
    @a.submit(data, data.buttons.first)
  end

  def get_dns_list(domain)
    fn,da,rd = parse_dns(domain)
    p = @a.get(@url + 'cs/dns/detail/?domain=' + rd)
    #p.parser.at_css("table#dns_records").at_css("tbody").search('tr')[0].search('td')[5].at_css('a')
    p.parser.at_css("table#dns_records").at_css("tbody").search('tr').each do |tr|
      tds = tr.search('td')
      name = ActionController::Base.helpers.strip_tags tds[0].inner_html.strip
      if name == fn + "."
        return tds[5].at_css('a').attr('href')
      end
    end
    nil
  end

  def set_dns(domain, value)
    @a ||= init_dns
    # jestli existuje nastav a odejdi
    dns = get_dns_list(domain)
    if dns
      update_dns dns, value
      return "set txt record to: #{value}"
    else
      # neexistuje vytvor, nastav a odejdi
      create_dns domain, value
      return "create txt recor #{value}"
    end
  end

end