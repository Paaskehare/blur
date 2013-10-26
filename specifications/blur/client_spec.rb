require_relative '../spec_helper'

describe Blur::Client do
  let(:networks) { [{ nickname: 'test', host: 'uplink.io', channels: %w{#test} }] }
  let(:options)  { { :networks => networks } }
  subject { Blur::Client.new options }

  describe "default attributes" do
    it "should have a set of options" do
      expect(subject.options).to be_kind_of Hash
    end

    it "should have a list of networks" do
      expect(subject.networks).to be_kind_of Array
    end

    it "should have a list of scripts" do
      expect(subject.scripts).to be_kind_of Array
    end
  end

  describe ".new" do
    it "should load scripts" do
      expect_any_instance_of(Blur::Client).to receive :load_scripts

      subject # instantiates the client
    end

    it "should instantiate the networks from options" do
      expect(Blur::Network).to receive(:new).at_least(networks.count).times

      subject # instantiates the client
    end
  end

  describe "#connect" do
    before :each do
      allow(EventMachine).to receive(:run).and_yield
    end

    it "should run the eventmachine loop" do
      allow(EventMachine).to receive :run
      expect(EventMachine).to receive :run

      subject.connect
    end

    it "should set a delegate on each network" do
      network = double(:network, :connected? => false).as_null_object

      expect(network).to receive :delegate=

      subject.networks = [network]
      subject.connect
    end

    it "should connect to each network" do
      network = double(:network, :connected? => false).as_null_object

      expect(network).to receive :connect

      subject.networks = [network]
      subject.connect
    end
  end
end
