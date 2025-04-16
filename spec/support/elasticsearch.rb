RSpec.configure do |config|
  config.before(:each) do
    stub_request(:any, /localhost:9200/)
      .to_return(
        status: 200,
        body: {
          name: "elasticsearch",
          cluster_name: "docker-cluster",
          version: { number: "7.2.1", build_flavor: "default" },
          tagline: "You Know, for Search"
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end
