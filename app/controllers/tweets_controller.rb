class TweetsController < ApplicationController

  $regex_emoji = /[\u{203C}\u{2049}\u{20E3}\u{2122}\u{2139}\u{2194}-\u{2199}\u{21A9}-\u{21AA}\u{231A}-\u{231B}\u{23E9}-\u{23EC}\u{23F0}\u{23F3}\u{24C2}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}\u{2600}-\u{2601}\u{260E}\u{2611}\u{2614}-\u{2615}\u{261D}\u{263A}\u{2648}-\u{2653}\u{2660}\u{2663}\u{2665}-\u{2666}\u{2668}\u{267B}\u{267F}\u{2693}\u{26A0}-\u{26A1}\u{26AA}-\u{26AB}\u{26BD}-\u{26BE}\u{26C4}-\u{26C5}\u{26CE}\u{26D4}\u{26EA}\u{26F2}-\u{26F3}\u{26F5}\u{26FA}\u{26FD}\u{2702}\u{2705}\u{2708}-\u{270C}\u{270F}\u{2712}\u{2714}\u{2716}\u{2728}\u{2733}-\u{2734}\u{2744}\u{2747}\u{274C}\u{274E}\u{2753}-\u{2755}\u{2757}\u{2764}\u{2795}-\u{2797}\u{27A1}\u{27B0}\u{2934}-\u{2935}\u{2B05}-\u{2B07}\u{2B1B}-\u{2B1C}\u{2B50}\u{2B55}\u{3030}\u{303D}\u{3297}\u{3299}\u{1F004}\u{1F0CF}\u{1F170}-\u{1F171}\u{1F17E}-\u{1F17F}\u{1F18E}\u{1F191}-\u{1F19A}\u{1F1E7}-\u{1F1EC}\u{1F1EE}-\u{1F1F0}\u{1F1F3}\u{1F1F5}\u{1F1F7}-\u{1F1FA}\u{1F201}-\u{1F202}\u{1F21A}\u{1F22F}\u{1F232}-\u{1F23A}\u{1F250}-\u{1F251}\u{1F300}-\u{1F320}\u{1F330}-\u{1F335}\u{1F337}-\u{1F37C}\u{1F380}-\u{1F393}\u{1F3A0}-\u{1F3C4}\u{1F3C6}-\u{1F3CA}\u{1F3E0}-\u{1F3F0}\u{1F400}-\u{1F43E}\u{1F440}\u{1F442}-\u{1F4F7}\u{1F4F9}-\u{1F4FC}\u{1F500}-\u{1F507}\u{1F509}-\u{1F53D}\u{1F550}-\u{1F567}\u{1F5FB}-\u{1F640}\u{1F645}-\u{1F64F}\u{1F680}-\u{1F68A}]/

  #require 'ngrams'
  #require 'engtagger' 
  #require 'sentimental'

  def index
    initiate()
  end


  def initiate
    readTweets()
    @sarcastic = Sarcastic.all
    @nonSarcastic = Nonsarcastic.all
    positives()
    @positives = Positive.all
    @searchTweets = Searchtweet.all
    detectSarcasm(Sarcastic, @sarcastic, @positives)
    detectSarcasm(Nonsarcastic, @nonSarcastic, @positives)

    #savetoCSV(@tweets)
    @tweets = Tweet.all
  end
  
  def search
    Searchtweet.destroy_all
    if params[:text].nil?
      redirect_to root_path, notice: "Text can't be blank!"
    else
      logger.debug "aqui"
      search_tweets(Searchtweet, params[:text])
      @tweetsSearch = Searchtweet.all
      @positives = Positive.all
      detectSarcasm(Searchtweet, @tweetsSearch, @positives)

    end
  end
  
  def analisar
    
   if params[:text].nil?
    redirect_to root_path, notice: "Text can't be blank!"
    else
       #@positives = Positive.all
      @ironic = detectSarcasmSentence(params[:text], Positive.all)
    end
  end
  
  def viewSarcastic
    
    @tweets = Sarcastic.all
  end

  def viewNonSarcastic
    
    @tweetsNS = Nonsarcastic.all
  end
  
  def readTweets
    require 'csv'
    i = 0
    CSV.foreach("app/controllers/sarcastica.csv") do |row|

      t = Sarcastic.new()
      t.text = row[0].to_s
      t.ironic = "no"
      t.save
      
      i = i + 1
    end
    
     CSV.foreach("app/controllers/naosarcastica.csv") do |row|

      t = Nonsarcastic.new()
      t.text = row[0].to_s
      t.ironic = "no"
      t.save
      
      i = i + 1
    end
    end
end

  def savetoCSV(tweets)
    require 'csv'
    CSV.open("senti.csv", "w") do |csv|
      csv << ["tweet", "irony"]
      tweets.each do |t|
        csv << [t.text, t.ironic]
      end
    end
  end
  
  def saveTextToDatabase(database, text)
    n = database.new()
    n.expression = text
    n.errors
    logger.debug n.save
  end  
  
  def positives()
    saveTextToDatabase(Positive, "love")
    saveTextToDatabase(Positive, "enjoy")
    saveTextToDatabase(Positive, "adore")
  end
  
  def detectSarcasm(base, tweets, positives)
    require 'longtextanalyzer'
    #byebug
    tweets = base.select(Arel.star).joins(
        base.arel_table.join(Positive.arel_table).on(
          Arel::Nodes::NamedFunction.new(
            'INSTR', [
              base.arel_table[:text], Positive.arel_table[:expression]
            ]
          ).gt(0)
        ).join_sources
      )  
      
      
     # Carregando os valores padrão da base SentiWordNet
    LongTextAnalyzer.load_defaults
    # Instanciando um analizador do SentiWordNet
    analyzer = LongTextAnalyzer.new
    
    arr = Array.new
    #sarcastics = negTweets & posTweets
    
    #Tweet.update(sarcastics, :ironic => 'yes')

    positives.each do |n|
      e = n.expression
      tweets.each do |t|
        t.text.sub! '#sarcasm', ''
        index = t.text.index(e)
        if index.nil?
          next
        end
        aux = t.text[(index+e.length)..-1]
        #logger.debug aux
        if not aux.nil?
          score = analyzer.get_score(aux)
          #logger.debug score
          if not score.nil?
            if score < 0
              arr.push(t.text)
              #logger.debug "IRONY"
            end
          end
        end
      end
    end
    
    base.where(:text =>arr).update_all(:ironic => "yes")
    logger.debug arr
    
  end
  
  
  def detectSarcasmSentence(text, positives)
    require 'longtextanalyzer'
    # Carregando os valores padrão da base SentiWordNet
    LongTextAnalyzer.load_defaults
    # Instanciando um analizador do SentiWordNet
    analyzer = LongTextAnalyzer.new
    
    arr = Array.new
    #sarcastics = negTweets & posTweets
    
    #Tweet.update(sarcastics, :ironic => 'yes')
    positives = ["love", "enjoy", "adore"]
    irony = "no"
    byebug
    positives.each do |n|
      
      e = n
        text.sub! '#sarcasm', ''
        index = text.index(e)
        if index.nil?
          next
        end
        aux = text[(index+e.length)..-1]
        #logger.debug aux
        if not aux.nil?
          score = analyzer.get_score(aux)
          #logger.debug score
          if not score.nil?
            if score < 0
              arr.push(text)
              irony = "yes"
              byebug
              break
              #logger.debug "IRONY"
            end
          end
        end
      
    end
    tweet = Tweet.new()
    tweet.text = text
    tweet.ironic = irony
    tweet.save
    irony
  end
  
  def search_tweets(base, text)
    client = Twitter::REST::Client.new do |config|
      config.consumer_key    = "TsowEgvrnhLiG43ZcFAGwTPoF"
      config.consumer_secret = "FWXuCWA2Q1FcwVr3mE7n767vf5ZNihnYnUc5iE3ot1y6rOLwjy"
    end

    results = client.search("#{text} -rt", lang: "en", count: 1000)
    
    results.to_h[:statuses].each { |t|
      already_created = base.where(:origin_id => t[:id]).first
      if t[:text].include? "http" or t[:text].include? "www"  or t[:text].include? "@" or t[:text].include? "https"
        next
      end
      if already_created.present?
        # Apenas indica que este post foi encontrado pela query passada
        #if !already_created.queries.exists?(query)
        #  already_created.queries << query
        #  already_created.save
        #end
      else
        clean_text = t[:text].gsub $regex_emoji, ''
        #logger.debug "#{query.inspect}"
        # Se não, cria um novo post caso seu texto retirando caracteres inválidos para o banco e também associa à esta query
        if clean_text.length > 0
          tweet = base.new()
          tweet.text = clean_text
          tweet.origin_id = t[:id]
          tweet.ironic = "no"
          tweet.save
        end
      end
    }
  end