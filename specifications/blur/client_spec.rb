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

    it "should run the event loop" do
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

  describe "#got_command" do
    before :each do
      allow(subject).to receive :got_milk
      allow(subject).to receive :log # stub out to remove noisy debug messages
    end

    let(:network) { double :network }

    context "when the command matches a method" do
      let(:command) { double name: :milk, params: %w{got milk?} }

      it "should call matching method" do
        expect(subject).to receive(:got_milk).with network, command

        subject.got_command network, command
      end
    end

    context "when the command does not match a method" do
      let(:command) { double name: :candy, params: %w{well? do you?} }

      it "should not call anything" do
        allow(subject).to receive(:respond_to?).and_return false # the rspec expectation defines subject.got_candy :/
        expect(subject).to_not receive :got_candy

        subject.got_command network, command
      end
    end
  end

  describe "#load_scripts" do
    let(:scripts) { %w{script1 script2} }

    before do
      allow(Dir).to receive(:glob).and_return scripts
      allow(Blur::Script).to receive(:new).and_return double.as_null_object
    end

    it "should find scripts" do
      expect(Dir).to receive(:glob).with(/\/scripts\//).at_least(:once).and_return []

      subject.load_scripts
    end

    it "should load scripts" do
      scripts.each do |path|
        expect(Blur::Script).to receive(:new).with path
      end

      subject.load_scripts
    end

    it "should pass reference to scripts" do
      subject # intentional
      script = double 'script'
      allow(Blur::Script).to receive(:new).and_return script

      expect(script).to receive(:__client=).twice

      subject.load_scripts
    end
  end

  describe "#quit" do
    let(:networks) { [double('network').as_null_object, double('network').as_null_object] }

    before do
      allow(EventMachine).to receive :stop
      allow(subject).to receive :unload_scripts

      subject.networks = networks
    end

    it "should send graceful quit" do
      subject.networks.each do |network|
        expect(network).to receive(:transmit).with :QUIT, anything
      end

      subject.quit
    end

    it "should disconnect all networks" do
      subject.networks.each do |network|
        expect(network).to receive :disconnect
      end

      subject.quit
    end

    it "should unload scripts" do
      expect(subject).to receive :unload_scripts

      subject.quit
    end

    it "should stop the event loop" do
      expect(EventMachine).to receive :stop

      subject.quit
    end
  end

  describe "#network_connection_closed" do
    it "should emit :connection_closed"
  end

  describe "#unload_scripts" do
    it "should unload scripts"
    it "should clear the list of scripts"
  end
end
