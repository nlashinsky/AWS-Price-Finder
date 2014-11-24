## require the Rails application environment which will give us access to our project's data models & gems
 require File.dirname(File.expand_path(File.dirname(__FILE__))) + "/config/environment"
 require 'pp'
 require 'csv'

## loop through each of the items in the database

Item.limit(20).each do |item|
 
#   ##collect the item data that we will use in our AWS query
#   ##TODO - you may want to sanitize these!

  brand = item.company_name  #Obviously, you'll want to name based on your own Rails app schema.
  name = item.name
  color = item.color
 
  puts "==  Processing Brand:  #{brand}       Product: #{name} ==\n"
  puts "========================x=========================\n"
 
  # initialize a new AWS query using the Vacuum Ruby wrapper
  request_raw = Vacuum.new
 
  # configure AWS query with credentials
  # TODO: don't hardcode these
  request_raw.configure(
    aws_access_key_id:     ENV['AMAZON_API_ACCESS_KEY'],
    aws_secret_access_key: ENV['AMAZON_API_SECRET_ACCESS_KEY'],
    associate_tag:         ENV['AMAZON_ASSOCIATE_TAG']
  )  
 
  # set up the parameters of our query using item data; run the query
  params_raw = {
    'SearchIndex' => 'Books' #Search index here i.e. 'Beauty',
    'Keywords'    => [brand, name, color].join(' '), #Keywords go here:
    'ResponseGroup' => 'Request'
  }
  
  response_from_raw_request = request_raw.item_search(query: params_raw, persistent: true)
 
  puts "==  Result of query to get ASIN... ==\n"
  
  # print out the result ASIN of the query 
  parsed_response_from_raw_request = response_from_raw_request.to_h
  aws_ASIN = parsed_response_from_raw_request['ItemSearchResponse']['Items']['Item'][0]['ASIN']
  
  puts "ASIN is #{aws_ASIN}"

## Given the ASIN, we now make an API call to get rich Amazon product info

  request_more_info = Vacuum.new

  request_more_info.configure(
    aws_access_key_id:     ENV['AMAZON_API_ACCESS_KEY'],
    aws_secret_access_key: ENV['AMAZON_API_SECRET_ACCESS_KEY'],
    associate_tag:         ENV['AMAZON_ASSOCIATE_TAG']
    )  

  params_more_info = {
    'ItemId' => "#{aws_ASIN}", 
    'ResponseGroup' => 'Request, OfferSummary, ItemAttributes' #Specify what data you want to receive. See AWS docs. 

  response_with_more_info = request_more_info.item_lookup(query: params_more_info, persistent: true)

  puts "=== Results of query to get more info ==="

  #Convert XMl response to Hash Table 

  parsed_response_with_more_info = response_with_more_info.to_h
  
  ######You can also use this prety print "PP.pp" method below to look at pretty-print version of XML to determine XML path#####
  #puts PP.pp(parsed_response_with_more_info = response_with_more_info.to_h)

  ##parse for the ASIN, manufacturer, title and price
  # puts ASIN = parsed_response_with_more_info.inspect




  brand = parsed_response_with_more_info['ItemLookupResponse']['Items']['Item']['ItemAttributes']['Brand']
  manufacturer = parsed_response_with_more_info['ItemLookupResponse']['Items']['Item']['ItemAttributes']['Manufacturer']
  title = parsed_response_with_more_info['ItemLookupResponse']['Items']['Item']['ItemAttributes']['Title']
  weight_num = parsed_response_with_more_info['ItemLookupResponse']['Items']['Item']['ItemAttributes']['PackageDimensions']['Weight']['__content__']
  weight_units = parsed_response_with_more_info['ItemLookupResponse']['Items']['Item']['ItemAttributes']['PackageDimensions']['Weight']['Units']
  upc = parsed_response_with_more_info['ItemLookupResponse']['Items']['Item']['ItemAttributes']['UPC']
  description = parsed_response_with_more_info['ItemLookupResponse']['Items']['Item']['ItemAttributes']['Feature']
  
  puts "Brand: #{brand}" 
  puts "Manufacturer: #{manufacturer}" 
  puts "Title: #{title}"  
  puts "Weight:  #{weight_num}  #{weight_units}" 
  puts "UPC: #{upc}" 
  puts "Desc. #{description[0]}; #{description[1]}; #{description[2]}; #{description[3]}"



  ###TO DO - build in logic for finding pricing and  handling nil values 
  # if parsed_response_with_more_info['ItemLookupResponse']['Items']['Item']['ItemAttributes']['ListPrice']['FormattedPrice'] != nil 
  #   puts "Price: #{price_list}" 
  # else 
  #   if parsed_response_with_more_info['ItemLookupResponse']['Items']['Item']['OfferSummary']['LowestNewPrice']['FormattedPrice'] != nil 
  #     puts "Price: #{price_att}" 
  #   else puts "no price found"
  #   end 
  # end 

  # puts "\n========x===================================x======\n"
   end


  ##To DO

  #Create CSV export of items with brand, title, ASIN and pricing information

  ## Future idea: create rails app to match entered products from amazon API, and record results in database 


