require "test-unit"
require "fluent/test"
require "fluent/test/driver/filter"
require "fluent/test/helpers"
require "./lib/fluent/plugin/filter_masking.rb"

MASK_STRING = "*******"

class YourOwnFilterTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup # this is required to setup router and others
  end

  # default configuration for tests
  CONFIG = %[
    fieldsToMaskFilePath test/fields-to-mask
    fieldsToExcludeJSONPaths excludedField,exclude.path.nestedExcludedField
  ]

  # configuration for tests without exclude parameter
  CONFIG_NO_EXCLUDE = %[
    fieldsToMaskFilePath test/fields-to-mask
  ]

  # configuration for tests with case insensitive fields
  CONFIG_CASE_INSENSITIVE = %[
    fieldsToMaskFilePath test/fields-to-mask-insensitive
  ]

  # configuration for special json escaped cases
  CONFIG_SPECIAL_CASES = %[
    fieldsToMaskFilePath test/fields-to-mask
    fieldsToExcludeJSONPaths excludedField,exclude.path.nestedExcludedField
    handleSpecialEscapedJsonCases true
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::MaskingFilter).configure(conf)
  end

  def filter(config, messages)
    d = create_driver(config)
    d.run(default_tag: "input.access") do
      messages.each do |message|
        d.feed(message)
      end
    end
    d.filtered_records
  end

  sub_test_case 'plugin will mask all fields that need masking - case sensitive fields' do
    test 'mask field in hash object' do
      conf = CONFIG_NO_EXCLUDE
      messages = [
        {:not_masked_field=>"mickey-the-dog", :email=>"mickey-the-dog@zooz.com"}
      ]
      expected = [
        {:not_masked_field=>"mickey-the-dog", :email=>MASK_STRING}
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask field in json string' do
      conf = CONFIG
      messages = [
        { :body => "{\"first_name\":\"mickey\",\"last_name\":\"the-dog\", \"type\":\"puggle\"}" }
      ]
      expected = [
        { :body => "{\"first_name\":\"*******\",\"last_name\":\"*******\", \"type\":\"puggle\"}" }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask field in hash object and in json string' do
      conf = CONFIG
      messages = [
        { :msg=>"sup", :email=>"mickey-the-dog@zooz.com", :body => "{\"first_name\":\"mickey\", \"type\":\"puggle\", \"last_name\":\"the-dog\"}", :status_code=>201, :password=>"d0g!@"}
      ]
      expected = [
        { :msg=>"sup", :email=>MASK_STRING, :body => "{\"first_name\":\"*******\", \"type\":\"puggle\", \"last_name\":\"*******\"}", :status_code=>201, :password=>MASK_STRING }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask field in nested json string' do
      conf = CONFIG
      messages = [
        { :body => "{\"first_name\":\"mickey\",\"last_name\":\"the-dog\",\"address\":\"{\"street\":\"Austin\",\"number\":\"89\"}\", \"type\":\"puggle\"}" } 
      ]
      expected = [
        { :body => "{\"first_name\":\"*******\",\"last_name\":\"*******\",\"address\":\"{\"street\":\"*******\",\"number\":\"*******\"}\", \"type\":\"puggle\"}" }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask field in nested json escaped string' do
      conf = CONFIG
      messages = [
        { :body => "{\"first_name\":\"mickey\",\"last_name\":\"the-dog\",\"address\":\"{\\\"street\":\\\"Austin\\\",\\\"number\":\\\"89\\\"}\", \"type\":\"puggle\"}" } 
      ]
      expected = [
        { :body => "{\"first_name\":\"*******\",\"last_name\":\"*******\",\"address\":\"{\\\"street\\\":\\\"*******\\\",\\\"number\\\":\\\"*******\\\"}\", \"type\":\"puggle\"}" }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask field in hash object with exclude' do
      conf = CONFIG
      messages = [
        {:not_masked_field=>"mickey-the-dog", :email=>"mickey-the-dog@zooz.com", :first_name=>"Micky", :excludedField=>"first_name"}
      ]
      expected = [
        {:not_masked_field=>"mickey-the-dog", :email=>MASK_STRING, :first_name=>"Micky", :excludedField=>"first_name"}
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end
    
    test 'mask field in hash object with nested exclude' do
      conf = CONFIG
      messages = [
        {:not_masked_field=>"mickey-the-dog", :last_name=>"the dog", :email=>"mickey-the-dog@zooz.com", :first_name=>"Micky",  :exclude=>{:path=>{:nestedExcludedField=>"first_name,last_name"}}}
      ]
      expected = [
        {:not_masked_field=>"mickey-the-dog", :last_name=>"the dog", :email=>MASK_STRING, :first_name=>"Micky", :exclude=>{:path=>{:nestedExcludedField=>"first_name,last_name"}}}
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask field in hash object with base and nested exclude' do
      conf = CONFIG
      messages = [
        {:not_masked_field=>"mickey-the-dog", :last_name=>"the dog", :email=>"mickey-the-dog@zooz.com", :first_name=>"Micky", :excludedField=>"first_name", :exclude=>{:path=>{:nestedExcludedField=>"last_name"}}}
      ]
      expected = [
        {:not_masked_field=>"mickey-the-dog", :last_name=>"the dog", :email=>MASK_STRING, :first_name=>"Micky", :excludedField=>"first_name", :exclude=>{:path=>{:nestedExcludedField=>"last_name"}}}
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask field in json string with exclude' do
      conf = CONFIG
      messages = [
        { :body => "{\"first_name\":\"mickey\",\"last_name\":\"the-dog\", \"type\":\"puggle\"}", :excludedField=>"first_name" }
      ]
      expected = [
        { :body => "{\"first_name\":\"mickey\",\"last_name\":\"*******\", \"type\":\"puggle\"}", :excludedField=>"first_name" }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

  end

  sub_test_case 'plugin will mask all fields that need masking - case INSENSITIVE fields' do

    test 'mask field in hash object with camel case' do
      conf = CONFIG_CASE_INSENSITIVE
      messages = [
        {:not_masked_field=>"mickey-the-dog", :Email=>"mickey-the-dog@zooz.com"}
      ]
      expected = [
        {:not_masked_field=>"mickey-the-dog", :email=>MASK_STRING}
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'not mask field in hash object since case not match' do
      conf = CONFIG_CASE_INSENSITIVE
      messages = [
        {:not_masked_field=>"mickey-the-dog", :FIRST_NAME=>"mickey-the-dog@zooz.com"}
      ]
      expected = [
        {:not_masked_field=>"mickey-the-dog", :FIRST_NAME=>"mickey-the-dog@zooz.com"}
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask field in hash object with snakecase' do
      conf = CONFIG_CASE_INSENSITIVE
      messages = [
        {:not_masked_field=>"mickey-the-dog", :LaSt_NaMe=>"mickey-the-dog@zooz.com"}
      ]
      expected = [
        {:not_masked_field=>"mickey-the-dog", :last_name=>MASK_STRING}
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'mask case insensitive and case sensitive field in nested json escaped string' do
      conf = CONFIG_CASE_INSENSITIVE
      messages = [
        { :body => "{\"firsT_naMe\":\"mickey\",\"last_NAME\":\"the-dog\",\"address\":\"{\\\"Street\":\\\"Austin\\\",\\\"number\":\\\"89\\\"}\", \"type\":\"puggle\"}" } 
      ]
      expected = [
        { :body => "{\"firsT_naMe\":\"mickey\",\"last_name\":\"*******\",\"address\":\"{\\\"street\\\":\\\"*******\\\",\\\"number\\\":\\\"*******\\\"}\", \"type\":\"puggle\"}" }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

  end

  sub_test_case 'plugin will mask all fields that need masking - special json escaped cases' do
    test 'mask field in nested json escaped string when one of the values ends with "," (the value for "some_custom" field)' do
      conf = CONFIG_SPECIAL_CASES
      messages = [
        { :body => "{\"first_name\":\"mickey\",\"last_name\":\"the-dog\",\"address\":\"{\\\"street\":\\\"Austin\\\",\\\"number\":\\\"89\\\"}\", \"type\":\"puggle\", \"cookie\":\"some_custom=,,live,default,,2097403972,2.22.242.38,\", \"city\":\"new york\"}" } 
      ]
      expected = [
        { :body => "{\"first_name\":\"*******\",\"last_name\":\"*******\",\"address\":\"{\\\"street\\\":\\\"*******\\\",\\\"number\\\":\\\"*******\\\"}\", \"type\":\"puggle\", \"cookie\":\"*******\", \"city\":\"new york\"}" }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end


    test 'mask field in nested json escaped string with long lines' do
      conf = CONFIG_SPECIAL_CASES
      messages = [
        { :body => "{\"kubernetes\":{\"container_image\":\"docker-registry.gitlab.co:1234\\\/testing\\\/logging-service\\\/tags:v1.2.4\",\"container_name\":\"logging-service\",\"host\":\"ip-123-123-123-123.eu-central-2.compute.internal\",\"labels\":{\"app\":\"logging-gateway-service\",\"deployed_from_master\":\"false\",\"deployed_from_tag\":\"true\",\"deployment_tool_version\":\"k8s-tool-10.0.24\",\"instance_tag\":\"v1.2.4\",\"maskExclude\":\"email\",\"pod-template-hash\":\"6c74f7bdf6\",\"security.moti.io\\\/tlsMode\":\"moti\",\"service.moti.io\\\/canonical-name\":\"logging-gateway-service\",\"service.moti.io\\\/canonical-revision\":\"latest\"},\"namespace_name\":\"apps\",\"pod_id\":\"5f2474fd-d4ff-4842-b76f-143f240b0b28\",\"pod_name\":\"logging-gateway-service-deployment-6c74f7bdf6-lkbcq\"},\"message\":{\"name\":\"logging-gateway-logger\",\"hostname\":\"logging-gateway-service-deployment-88dd9f896-9bb8p\",\"pid\":1,\"level\":30,\"plugin_name\":\"some_plugin\",\"service_name\":\"sure-route-static-object\",\"gateway\":\"my-gateway\",\"original_request\":{\"method\":\"GET\",\"headers\":{\"host\":\"external.production.co\",\"x-forwarded-client-cert\":\"By=spiffe:\\\/\\\/cluster.local\\\/ns\\\/moti\\\/sa\\\/default;Hash=dfdsfdsfdsdsfdsdsdfdse9add38f1f99d9d022ef60a37d6269ec;Subject=\\\"\\\";URI=spiffe:\\\/\\\/cluster.local\\\/ns\\\/moti-system\\\/sa\\\/moti-ingressgateway-service-account\",\"x-moti-unique-id\":\"11111111\",\"moti-origin-hop\":\"2\",\"true-client-ip\":\"18.197.9.181\",\"x-b3-traceid\":\"e7f3b3bd9fc9d048886e2135a87af23a\",\"x-moti-server-time\":\"1634041132\",\"x-b3-spanid\":\"87b9c2d116f54ce9\",\"x-b3-sampled\":\"0\",\"x-request-id\":\"9989b2a9-408c-4ba2-ad15-2f11dd678ab6\",\"cookie\":\"some_custom=,,live,default,,1111111,3.3.3.3,\",\"strict-transport-security\":\"max-age=15768000; includeSubDomains\",\"via\":\"1.1 v1-moti.net(ghost) (moti), 1.1 moti.net(ghost) (moti)\",\"accept\":\"*\\\/*\",\"x-forwarded-for\":\"1.1.1.1, 1.1.1.1, 2.2.2.2\",\"x-moti-config-log-detail\":\"true\",\"cache-control\":\"no-cache, max-age=0\",\"x-forwarded-proto\":\"http\",\"content-length\":\"0\",\"pragma\":\"no-cache\",\"user-agent\":\"ELB-HealthChecker\\\/2.0\",\"x-guy-original-path\":\"\\\/admin-api-gateway-dbless\\\/sure-route\",\"x-guy-external-address\":\"11.28.29.60\",\"x-moti-edgescape\":\"georegion=125,country_code=DE,region_code=DE,city=FRANKFURT,lat=43.11,long=12.12,timezone=GMT+5,continent=EU,throughput=vhigh,bw=2000,network=aws,asnum=12345,network_type=hosted,location_id=0\",\"x-b3-parentspanid\":\"886e21mmmwwwa\"},\"uri\":\"\\\/sure-route\",\"body\":[]},\"stage\":\"log\",\"additional_info\":{\"response_body\":\"\\\"<!DOCTYPE html PUBLIC \\\\\\\"-\\\/\\\/W3C\\\/\\\/DTD HTML 4.01 Transitional\\\/\\\/EN\\\\\\\">\\\\r\\\\n<html>\\\\r\\\\n<head>\\\\r\\\\n\\\\r\\\\n  <meta http-equiv=\\\\\\\"Content-Type\\\\\\\" content=\\\\\\\"text\\\/html; charset=ISO-8859-1\\\\\\\">\\\\r\\\\n  <title>Neque porro quisquam est qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit<\\\/title>\\\\r\\\\n  <style type=\\\\\\\"text\\\/css\\\\\\\">\\\\r\\\\n\\\/*<![CDATA[ XML blockout *\\\/\\\\r\\\\n\\\\r\\\\n\\\/* XML end ]]>*\\\/\\\\r\\\\n  <\\\/style>\\\\r\\\\n<\\\/head>\\\\r\\\\n\\\\r\\\\n\\\\r\\\\n<body>\\\\r\\\\n\\\\r\\\\n<h2>Lorem Ipsum<\\\/h2>\\\\r\\\\n\\\\r\\\\n<h1>Ipsum, Lorem<\\\/h1>\\\\r\\\\n\\\\r\\\\n<div id=\\\\\\\"lipsum\\\\\\\">\\\\r\\\\n<p>\\\\r\\\\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam massa enim, tincidunt non hendrerit eget, malesuada et nisi. In hac habitasse platea dictumst. Praesent nec laoreet ante. Aenean tempus nisi in erat tempus tempus. Vestibulum imperdiet lobortis sapien eu tempus. Vivamus volutpat quam sed eros molestie vitae dignissim nulla ultricies. Vivamus dictum elit velit. Pellentesque pellentesque ornare ornare. Mauris vel gravida sapien. Praesent eleifend tristique ipsum nec tempor. Vestibulum cursus eleifend tellus, a egestas lectus euismod sed.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\nDuis nec massa quam. Nulla porta, enim ut consequat tincidunt, quam tortor consequat enim, eu interdum eros lorem eu turpis. Cras vestibulum orci quis felis tristique quis semper sem imperdiet. Sed mattis tincidunt risus scelerisque scelerisque. Aliquam nisl quam, bibendum quis luctus eu, sodales ut felis. Integer id turpis nisi. Phasellus mattis nulla eu odio faucibus a auctor orci tristique. Nulla ullamcorper, risus nec semper accumsan, libero lacus aliquet elit, quis lacinia metus nunc vestibulum turpis. Suspendisse vel sapien vel magna auctor aliquam. Aenean fringilla fringilla metus non imperdiet. Aliquam nisl lacus, tempus vitae commodo non, accumsan ut lectus. Nam in urna eu neque pretium aliquam. Maecenas sit amet urna lectus. Donec vitae metus enim.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\nSed lacus nulla, faucibus eget ullamcorper ut, mollis at metus. Vivamus tortor felis, tincidunt at tristique ut, tincidunt feugiat velit. Ut euismod felis non urna luctus luctus. Integer nec urna massa. Mauris vestibulum hendrerit auctor. Morbi at tellus nec arcu scelerisque rhoncus. Phasellus facilisis interdum lorem vulputate posuere. Nullam quis felis est. Aenean metus augue, tempus non ultricies et, dapibus vel felis. Pellentesque at augue velit. Nulla erat nisi, posuere eu pellentesque id, pretium ac libero. Phasellus tincidunt sollicitudin sapien at mollis. Nullam et libero velit, nec tincidunt eros. Aliquam et sem elit. Quisque suscipit orci enim, vel aliquam nisi. Suspendisse in enim a ligula blandit volutpat in id velit.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\nNam tempor neque nec ligula sollicitudin rhoncus. Etiam et lorem vel odio pharetra interdum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. In imperdiet nisi sed diam rutrum gravida in vel massa. Nam ullamcorper ultrices diam, vitae consequat lacus consequat consequat. Curabitur laoreet leo sed tortor fringilla nec euismod libero lobortis. Donec non enim lectus. Suspendisse potenti. In hac habitasse platea dictumst. Fusce semper auctor neque nec lobortis. Praesent vitae mauris turpis. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin sed pharetra odio. Suspendisse potenti. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Duis eget odio purus, quis dapibus massa.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\nCurabitur ut dapibus eros. Donec tempor, felis ac facilisis bibendum, nisi purus pellentesque sem, sollicitudin tempor lectus nulla at mi. Maecenas quis urna ut ante pulvinar pellentesque. Duis auctor imperdiet suscipit. Pellentesque dui nulla, volutpat quis posuere a, gravida ornare augue. Proin nec felis pharetra magna pellentesque facilisis. Curabitur lacus libero, malesuada sed tincidunt ac, aliquet ut tortor. Etiam gravida lorem nulla, consectetur eleifend risus. Donec facilisis, turpis laoreet imperdiet laoreet, purus justo egestas nulla, et hendrerit leo eros at orci. Nunc vulputate mauris sit amet sapien accumsan nec euismod orci volutpat. Sed ultricies velit ut lorem venenatis in convallis tellus imperdiet. Aenean auctor ultrices est ultricies rhoncus. Phasellus non magna a leo luctus fermentum nec fermentum erat.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\n\\\\r\\\\nSed faucibus nisl quis diam mollis quis varius tortor tincidunt. Phasellus in turpis in tellus consectetur mollis. Donec a neque id metus condimentum dignissim. In hac habitasse platea dictumst. Pellentesque sem nisi, pulvinar nec sagittis vitae, lacinia non tellus. Aliquam dignissim dignissim volutpat. Pellentesque ut quam et mi tincidunt varius id vel quam. Duis consectetur elit ac ligula fringilla elementum. In elementum tellus viverra mi vehicula vitae tempus lectus laoreet. Nullam diam nibh, tincidunt vitae imperdiet a, luctus a felis. In posuere pulvinar volutpat. Pellentesque eget viverra justo.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\nNullam nec sapien at felis molestie auctor. Sed dignissim erat eu nulla ullamcorper mattis. Curabitur felis sem, feugiat non semper ut, sollicitudin sed ipsum. Quisque cursus laoreet turpis, sit amet molestie neque consequat at. Vestibulum eu ligula quis nisl pulvinar rhoncus. Praesent faucibus, dolor in elementum ullamcorper, tellus ante mattis risus, ac imperdiet eros eros quis risus. Praesent luctus libero a diam pharetra eget placerat risus pulvinar. Donec sollicitudin pulvinar velit vel pellentesque. Quisque sagittis leo ac mauris congue adipiscing. In tempus facilisis facilisis. Aliquam erat volutpat. Suspendisse sagittis libero ipsum.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\nAliquam at cursus ipsum. Vivamus purus mi, pretium at molestie id, dictum in quam. Proin egestas auctor iaculis. Maecenas sodales facilisis tellus eu bibendum. Vestibulum varius vehicula scelerisque. Praesent condimentum varius commodo. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Donec sem nisl, sagittis eu euismod non, tempor nec magna. Fusce sed auctor nisl. Phasellus porttitor sagittis est, sit amet eleifend elit dignissim et. Nam consectetur elementum elit non egestas. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum a ultricies neque. Integer hendrerit nisi id dolor porta quis venenatis lacus dignissim. In vitae fringilla magna.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\nFusce ultrices scelerisque felis, id semper quam posuere a. Sed nec erat eget velit euismod condimentum a in enim. Maecenas bibendum aliquam tincidunt. Mauris vestibulum neque at nulla sagittis id lacinia enim fermentum. Quisque adipiscing risus nec massa auctor condimentum. Mauris venenatis lacus justo, eu varius odio. Fusce commodo luctus felis, vitae lobortis lectus facilisis id. Nunc faucibus vestibulum urna et lacinia. Cras ornare quam neque, non gravida sapien. Cras porta, diam sit amet laoreet rutrum, massa erat commodo diam, eu rhoncus nisl massa ac metus. In sem mauris, venenatis nec euismod ac, suscipit condimentum neque. Quisque pretium blandit lectus, ut aliquet neque rhoncus eu. Vivamus ultrices porttitor tincidunt. Curabitur ut ipsum non ipsum ultrices tincidunt. Integer scelerisque augue nec nisl varius tristique. Morbi condimentum rutrum sodales. Pellentesque odio mauris, porttitor ac sollicitudin in, ultrices ut diam.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\nSed congue adipiscing orci a pellentesque. Etiam quis neque eu nulla viverra egestas. Ut ultricies dui non enim rhoncus laoreet. Nulla molestie nibh non erat venenatis gravida. Pellentesque faucibus sem sit amet risus tincidunt non ultrices diam auctor. Praesent quis libero et tellus tempor molestie. Mauris ullamcorper feugiat libero sed elementum. Donec eget nunc eget diam hendrerit pulvinar. Ut ut imperdiet enim. Vestibulum sed quam lorem. Nunc ipsum massa, venenatis eget condimentum at, ornare id ante. Vestibulum ornare volutpat tincidunt. Etiam a eros erat. Curabitur lobortis, nisi a malesuada tincidunt, nisi enim congue eros, in dictum elit odio at nunc. Nam hendrerit porta velit a viverra.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\nEtiam vel velit urna. Donec commodo aliquet magna rhoncus pretium. Donec fermentum orci in diam dictum non pulvinar mi tristique. Morbi urna libero, sagittis vel facilisis nec, ornare vitae nunc. Pellentesque laoreet mi a mi condimentum sagittis. Donec eleifend, nisi sit amet tincidunt sollicitudin, leo magna accumsan elit, at adipiscing velit lacus id purus. Aenean nunc sapien, egestas vitae pretium viverra, bibendum vel tellus. Maecenas mattis dui ac justo facilisis sollicitudin. Proin in mi ac lacus hendrerit congue ac vitae elit. Aliquam erat volutpat. In hac habitasse platea dictumst. Phasellus dapibus diam vel velit consectetur tempor. Maecenas viverra suscipit bibendum. Sed non enim neque.\\\\r\\\\n<\\\/p>\\\\r\\\\n\\\\r\\\\n<p>\\\\r\\\\nCum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Phasellus at odio et odio volutpat egestas. Fusce non pellentesque felis. Nunc fermentum posuere sem quis egestas. Integer nec orci vel eros fringilla bibendum. Praesent placerat molestie elit at mattis. Nunc rutrum faucibus arcu non bibendum. Vestibulum at sapien sit amet sem iaculis congue. Morbi tempus, libero vitae interdum suscipit, lacus ipsum suscipit quam, non pretium nulla orci eget dui. Praesent et nisl turpis, ultricies convallis quam. In tempor urna et eros aliquet accumsan. Phasellus lobortis bibendum libero sit amet viverra. Aenean consectetur, neque eu cursus posuere, est leo molestie dui, sit amet vulputate mi erat eu tortor. Suspendisse arcu velit, porta sit amet adipiscing sed, ultrices id urna. In hendrerit iaculis massa in pretium. Vivamus eros augue, venenatis non hendrerit a, bibendum in tortor. Fusce et mauris lorem, vitae semper ligula. Nam iaculis, eros eu varius varius, orci sapien rhoncus arcu, et luctus urna lectus non quam. Donec gravida convallis justo at bibendum. Quisque non est velit, sed laoreet augue.\\\\r\\\\n<\\\/p>\\\\r\\\\n<\\\/div>\\\\r\\\\n\\\\r\\\\n<\\\/body>\\\\r\\\\n<\\\/html>\\\\r\\\\n\\\"\",\"kong_plugins_latency\":0,\"response_status_code\":200,\"total_elapsed\":0,\"response_headers\":{\"id\":\"a3a98b80-daf2-4d4b-8f27-946c4948c5a5\",\"content-type\":\"text\\\/html; charset=\\\"utf-8\\\"\",\"connection\":\"close\",\"content-length\":\"11375\"}},\"real_log_timestamp\":1634041132026.6,\"route_name\":\"sure-route-route\",\"context\":[],\"id\":\"a3a98b80-daf2-4d4b-8f27-946c4948c5a5\",\"msg\":\"response to client\",\"time\":\"2021-10-12T12:18:52.029Z\",\"v\":0}}" }
      ]
      expected = [
        { :body => "{\"kubernetes\":{\"container_image\":\"docker-registry.gitlab.co:1234\\\/testing\\\/logging-service\\\/tags:v1.2.4\",\"container_name\":\"logging-service\",\"host\":\"ip-123-123-123-123.eu-central-2.compute.internal\",\"labels\":{\"app\":\"logging-gateway-service\",\"deployed_from_master\":\"false\",\"deployed_from_tag\":\"true\",\"deployment_tool_version\":\"k8s-tool-10.0.24\",\"instance_tag\":\"v1.2.4\",\"maskExclude\":\"email\",\"pod-template-hash\":\"6c74f7bdf6\",\"security.moti.io\\\/tlsMode\":\"moti\",\"service.moti.io\\\/canonical-name\":\"logging-gateway-service\",\"service.moti.io\\\/canonical-revision\":\"latest\"},\"namespace_name\":\"apps\",\"pod_id\":\"5f2474fd-d4ff-4842-b76f-143f240b0b28\",\"pod_name\":\"logging-gateway-service-deployment-6c74f7bdf6-lkbcq\"},\"message\":{\"name\":\"logging-gateway-logger\",\"hostname\":\"logging-gateway-service-deployment-88dd9f896-9bb8p\",\"pid\":1,\"level\":30,\"plugin_name\":\"some_plugin\",\"service_name\":\"sure-route-static-object\",\"gateway\":\"my-gateway\",\"original_request\":{\"method\":\"GET\",\"headers\":{\"host\":\"external.production.co\",\"x-forwarded-client-cert\":\"By=spiffe:\\\/\\\/cluster.local\\\/ns\\\/moti\\\/sa\\\/default;Hash=dfdsfdsfdsdsfdsdsdfdse9add38f1f99d9d022ef60a37d6269ec;Subject=\\\"\\\";URI=spiffe:\\\/\\\/cluster.local\\\/ns\\\/moti-system\\\/sa\\\/moti-ingressgateway-service-account\",\"x-moti-unique-id\":\"11111111\",\"moti-origin-hop\":\"2\",\"true-client-ip\":\"18.197.9.181\",\"x-b3-traceid\":\"e7f3b3bd9fc9d048886e2135a87af23a\",\"x-moti-server-time\":\"1634041132\",\"x-b3-spanid\":\"87b9c2d116f54ce9\",\"x-b3-sampled\":\"0\",\"x-request-id\":\"9989b2a9-408c-4ba2-ad15-2f11dd678ab6\",\"cookie\":\"*******\",\"strict-transport-security\":\"max-age=15768000; includeSubDomains\",\"via\":\"1.1 v1-moti.net(ghost) (moti), 1.1 moti.net(ghost) (moti)\",\"accept\":\"*\\\/*\",\"x-forwarded-for\":\"1.1.1.1, 1.1.1.1, 2.2.2.2\",\"x-moti-config-log-detail\":\"true\",\"cache-control\":\"no-cache, max-age=0\",\"x-forwarded-proto\":\"http\",\"content-length\":\"0\",\"pragma\":\"no-cache\",\"user-agent\":\"ELB-HealthChecker\\\/2.0\",\"x-guy-original-path\":\"\\\/admin-api-gateway-dbless\\\/sure-route\",\"x-guy-external-address\":\"11.28.29.60\",\"x-moti-edgescape\":\"georegion=125,country_code=DE,region_code=DE,city=FRANKFURT,lat=43.11,long=12.12,timezone=GMT+5,continent=EU,throughput=vhigh,bw=2000,network=aws,asnum=12345,network_type=hosted,location_id=0\",\"x-b3-parentspanid\":\"886e21mmmwwwa\"},\"uri\":\"\\\/sure-route\",\"body\":[]},\"stage\":\"log\",\"additional_info\":{\"response_body\":\"\\\"<!DOCTYPE html PUBLIC \\\\\\\"-\\\/\\\/W3C\\\/\\\/DTD HTML 4.01 Transitional\\\/\\\/EN\\\\\\\">\\\\r\\\\n<html>\\\\r\\\\n<head>\\\\r\\\\n\\\\r\\\\n  <meta http-equiv=\\\\\\\"Content-Type\\\\\\\" content=\\\\\\\"text\\\/html; charset=ISO-8859-1\\\\\\\">\\\\r\\\\n  <title>Neque porro quisquam est qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit<\\\/title>\\\\r\\\\n  <style type=\\\\\\\"text\\\/css\\\\\\\">\\\\r\\\\n\\\/*<![CDATA[ XML blockout *\\\/\\\\r\\\\n\\\\r\\\\n\\\/* XML end ]]>*\\\/\\\\r\\\\n  <\\\/style>\\\\r\\\\n<\\\/head>\\\\r\\\\n\\\\r\\\\n\\\\r\\\\n<body>\\\\r\\\\n\\\\r\\\\n<h2>Lorem Ipsum<\\\/h2>\\\\r\\\\n\\\\r\\\\n<h1>Ipsum, Lorem<\\\/h1>\\\\r\\\\n\\\\r\\\\n<div id=\\\\\\\"lipsum\\\\\\\">\\\\r\\\\n<p>\\\\r\\\\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam massa enim, tincidunt non hendrerit eget, malesuada et nisi. In hac habitasse platea dictumst. Praesent nec laoreet ante. Aenean tempus nisi in erat tempus tempus. Vestibulum imperdiet lobortis sapien eu tempus. Vivamus volutpat quam sed eros molestie vitae dignissim nulla ultricies. Vivamus dictum elit velit. Pellentesque pellentesque ornare ornare. Mauris vel gravida sapien. Praesent eleifend tristique ipsum nec tempor. Vestibulum cursus eleifend tellus, a egestas lectus euismod sed.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\nDuis nec massa quam. Nulla porta, enim ut consequat tincidunt, quam tortor consequat enim, eu interdum eros lorem eu turpis. Cras vestibulum orci quis felis tristique quis semper sem imperdiet. Sed mattis tincidunt risus scelerisque scelerisque. Aliquam nisl quam, bibendum quis luctus eu, sodales ut felis. Integer id turpis nisi. Phasellus mattis nulla eu odio faucibus a auctor orci tristique. Nulla ullamcorper, risus nec semper accumsan, libero lacus aliquet elit, quis lacinia metus nunc vestibulum turpis. Suspendisse vel sapien vel magna auctor aliquam. Aenean fringilla fringilla metus non imperdiet. Aliquam nisl lacus, tempus vitae commodo non, accumsan ut lectus. Nam in urna eu neque pretium aliquam. Maecenas sit amet urna lectus. Donec vitae metus enim.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\nSed lacus nulla, faucibus eget ullamcorper ut, mollis at metus. Vivamus tortor felis, tincidunt at tristique ut, tincidunt feugiat velit. Ut euismod felis non urna luctus luctus. Integer nec urna massa. Mauris vestibulum hendrerit auctor. Morbi at tellus nec arcu scelerisque rhoncus. Phasellus facilisis interdum lorem vulputate posuere. Nullam quis felis est. Aenean metus augue, tempus non ultricies et, dapibus vel felis. Pellentesque at augue velit. Nulla erat nisi, posuere eu pellentesque id, pretium ac libero. Phasellus tincidunt sollicitudin sapien at mollis. Nullam et libero velit, nec tincidunt eros. Aliquam et sem elit. Quisque suscipit orci enim, vel aliquam nisi. Suspendisse in enim a ligula blandit volutpat in id velit.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\nNam tempor neque nec ligula sollicitudin rhoncus. Etiam et lorem vel odio pharetra interdum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. In imperdiet nisi sed diam rutrum gravida in vel massa. Nam ullamcorper ultrices diam, vitae consequat lacus consequat consequat. Curabitur laoreet leo sed tortor fringilla nec euismod libero lobortis. Donec non enim lectus. Suspendisse potenti. In hac habitasse platea dictumst. Fusce semper auctor neque nec lobortis. Praesent vitae mauris turpis. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin sed pharetra odio. Suspendisse potenti. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Duis eget odio purus, quis dapibus massa.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\nCurabitur ut dapibus eros. Donec tempor, felis ac facilisis bibendum, nisi purus pellentesque sem, sollicitudin tempor lectus nulla at mi. Maecenas quis urna ut ante pulvinar pellentesque. Duis auctor imperdiet suscipit. Pellentesque dui nulla, volutpat quis posuere a, gravida ornare augue. Proin nec felis pharetra magna pellentesque facilisis. Curabitur lacus libero, malesuada sed tincidunt ac, aliquet ut tortor. Etiam gravida lorem nulla, consectetur eleifend risus. Donec facilisis, turpis laoreet imperdiet laoreet, purus justo egestas nulla, et hendrerit leo eros at orci. Nunc vulputate mauris sit amet sapien accumsan nec euismod orci volutpat. Sed ultricies velit ut lorem venenatis in convallis tellus imperdiet. Aenean auctor ultrices est ultricies rhoncus. Phasellus non magna a leo luctus fermentum nec fermentum erat.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\n\\\\r\\\\nSed faucibus nisl quis diam mollis quis varius tortor tincidunt. Phasellus in turpis in tellus consectetur mollis. Donec a neque id metus condimentum dignissim. In hac habitasse platea dictumst. Pellentesque sem nisi, pulvinar nec sagittis vitae, lacinia non tellus. Aliquam dignissim dignissim volutpat. Pellentesque ut quam et mi tincidunt varius id vel quam. Duis consectetur elit ac ligula fringilla elementum. In elementum tellus viverra mi vehicula vitae tempus lectus laoreet. Nullam diam nibh, tincidunt vitae imperdiet a, luctus a felis. In posuere pulvinar volutpat. Pellentesque eget viverra justo.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\nNullam nec sapien at felis molestie auctor. Sed dignissim erat eu nulla ullamcorper mattis. Curabitur felis sem, feugiat non semper ut, sollicitudin sed ipsum. Quisque cursus laoreet turpis, sit amet molestie neque consequat at. Vestibulum eu ligula quis nisl pulvinar rhoncus. Praesent faucibus, dolor in elementum ullamcorper, tellus ante mattis risus, ac imperdiet eros eros quis risus. Praesent luctus libero a diam pharetra eget placerat risus pulvinar. Donec sollicitudin pulvinar velit vel pellentesque. Quisque sagittis leo ac mauris congue adipiscing. In tempus facilisis facilisis. Aliquam erat volutpat. Suspendisse sagittis libero ipsum.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\nAliquam at cursus ipsum. Vivamus purus mi, pretium at molestie id, dictum in quam. Proin egestas auctor iaculis. Maecenas sodales facilisis tellus eu bibendum. Vestibulum varius vehicula scelerisque. Praesent condimentum varius commodo. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Donec sem nisl, sagittis eu euismod non, tempor nec magna. Fusce sed auctor nisl. Phasellus porttitor sagittis est, sit amet eleifend elit dignissim et. Nam consectetur elementum elit non egestas. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum a ultricies neque. Integer hendrerit nisi id dolor porta quis venenatis lacus dignissim. In vitae fringilla magna.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\nFusce ultrices scelerisque felis, id semper quam posuere a. Sed nec erat eget velit euismod condimentum a in enim. Maecenas bibendum aliquam tincidunt. Mauris vestibulum neque at nulla sagittis id lacinia enim fermentum. Quisque adipiscing risus nec massa auctor condimentum. Mauris venenatis lacus justo, eu varius odio. Fusce commodo luctus felis, vitae lobortis lectus facilisis id. Nunc faucibus vestibulum urna et lacinia. Cras ornare quam neque, non gravida sapien. Cras porta, diam sit amet laoreet rutrum, massa erat commodo diam, eu rhoncus nisl massa ac metus. In sem mauris, venenatis nec euismod ac, suscipit condimentum neque. Quisque pretium blandit lectus, ut aliquet neque rhoncus eu. Vivamus ultrices porttitor tincidunt. Curabitur ut ipsum non ipsum ultrices tincidunt. Integer scelerisque augue nec nisl varius tristique. Morbi condimentum rutrum sodales. Pellentesque odio mauris, porttitor ac sollicitudin in, ultrices ut diam.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\nSed congue adipiscing orci a pellentesque. Etiam quis neque eu nulla viverra egestas. Ut ultricies dui non enim rhoncus laoreet. Nulla molestie nibh non erat venenatis gravida. Pellentesque faucibus sem sit amet risus tincidunt non ultrices diam auctor. Praesent quis libero et tellus tempor molestie. Mauris ullamcorper feugiat libero sed elementum. Donec eget nunc eget diam hendrerit pulvinar. Ut ut imperdiet enim. Vestibulum sed quam lorem. Nunc ipsum massa, venenatis eget condimentum at, ornare id ante. Vestibulum ornare volutpat tincidunt. Etiam a eros erat. Curabitur lobortis, nisi a malesuada tincidunt, nisi enim congue eros, in dictum elit odio at nunc. Nam hendrerit porta velit a viverra.\\\\r\\\\n<\\\/p>\\\\r\\\\n<p>\\\\r\\\\nEtiam vel velit urna. Donec commodo aliquet magna rhoncus pretium. Donec fermentum orci in diam dictum non pulvinar mi tristique. Morbi urna libero, sagittis vel facilisis nec, ornare vitae nunc. Pellentesque laoreet mi a mi condimentum sagittis. Donec eleifend, nisi sit amet tincidunt sollicitudin, leo magna accumsan elit, at adipiscing velit lacus id purus. Aenean nunc sapien, egestas vitae pretium viverra, bibendum vel tellus. Maecenas mattis dui ac justo facilisis sollicitudin. Proin in mi ac lacus hendrerit congue ac vitae elit. Aliquam erat volutpat. In hac habitasse platea dictumst. Phasellus dapibus diam vel velit consectetur tempor. Maecenas viverra suscipit bibendum. Sed non enim neque.\\\\r\\\\n<\\\/p>\\\\r\\\\n\\\\r\\\\n<p>\\\\r\\\\nCum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Phasellus at odio et odio volutpat egestas. Fusce non pellentesque felis. Nunc fermentum posuere sem quis egestas. Integer nec orci vel eros fringilla bibendum. Praesent placerat molestie elit at mattis. Nunc rutrum faucibus arcu non bibendum. Vestibulum at sapien sit amet sem iaculis congue. Morbi tempus, libero vitae interdum suscipit, lacus ipsum suscipit quam, non pretium nulla orci eget dui. Praesent et nisl turpis, ultricies convallis quam. In tempor urna et eros aliquet accumsan. Phasellus lobortis bibendum libero sit amet viverra. Aenean consectetur, neque eu cursus posuere, est leo molestie dui, sit amet vulputate mi erat eu tortor. Suspendisse arcu velit, porta sit amet adipiscing sed, ultrices id urna. In hendrerit iaculis massa in pretium. Vivamus eros augue, venenatis non hendrerit a, bibendum in tortor. Fusce et mauris lorem, vitae semper ligula. Nam iaculis, eros eu varius varius, orci sapien rhoncus arcu, et luctus urna lectus non quam. Donec gravida convallis justo at bibendum. Quisque non est velit, sed laoreet augue.\\\\r\\\\n<\\\/p>\\\\r\\\\n<\\\/div>\\\\r\\\\n\\\\r\\\\n<\\\/body>\\\\r\\\\n<\\\/html>\\\\r\\\\n\\\"\",\"kong_plugins_latency\":0,\"response_status_code\":200,\"total_elapsed\":0,\"response_headers\":{\"id\":\"a3a98b80-daf2-4d4b-8f27-946c4948c5a5\",\"content-type\":\"text\\\/html; charset=\\\"utf-8\\\"\",\"connection\":\"close\",\"content-length\":\"11375\"}},\"real_log_timestamp\":1634041132026.6,\"route_name\":\"sure-route-route\",\"context\":[],\"id\":\"a3a98b80-daf2-4d4b-8f27-946c4948c5a5\",\"msg\":\"response to client\",\"time\":\"2021-10-12T12:18:52.029Z\",\"v\":0}}" }
      ]
      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end
  end  
end